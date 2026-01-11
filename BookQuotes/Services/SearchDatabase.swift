import Foundation
import SQLite3

// MARK: - SearchDatabase Actor

/// Actor managing SQLite FTS5 database for blazing-fast full-text search.
/// Uses porter stemming for word variations and BM25 for relevance ranking.
actor SearchDatabase {
    private var db: OpaquePointer?
    private let dbPath: URL

    // MARK: - Initialization

    /// Initialize with default path in documents directory
    init() throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = docs.appendingPathComponent("search_index.sqlite")

        try openDatabase()
        try createFTSTables()
    }

    /// Initialize with a custom path (for testing)
    init(path: URL) throws {
        dbPath = path

        try openDatabase()
        try createFTSTables()
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Database Setup

    private func openDatabase() throws {
        guard sqlite3_open(dbPath.path, &db) == SQLITE_OK else {
            throw SearchError.databaseOpenFailed
        }
    }

    private func createFTSTables() throws {
        // FTS5 virtual table for quotes
        let createQuotesSQL = """
            CREATE VIRTUAL TABLE IF NOT EXISTS quotes_fts USING fts5(
                quote_id UNINDEXED,
                book_id UNINDEXED,
                text,
                margin_note,
                book_title,
                book_author,
                tokenize='porter unicode61'
            );
        """

        // FTS5 virtual table for books
        let createBooksSQL = """
            CREATE VIRTUAL TABLE IF NOT EXISTS books_fts USING fts5(
                book_id UNINDEXED,
                title,
                author,
                subtitle,
                tokenize='porter unicode61'
            );
        """

        try execute(createQuotesSQL)
        try execute(createBooksSQL)
    }

    // MARK: - Search Operations

    /// Search quotes and books with FTS5
    func search(query: String, scope: SearchScope) throws -> SearchResults {
        let ftsQuery = buildFTSQuery(query)
        guard !ftsQuery.isEmpty else {
            return .empty
        }

        var quotes: [SearchQuoteResult] = []
        var books: [SearchBookResult] = []

        if scope == .all || scope == .quotes {
            quotes = try searchQuotes(ftsQuery)
        }

        if scope == .all || scope == .books {
            books = try searchBooks(ftsQuery)
        }

        return SearchResults(quotes: quotes, books: books, query: query)
    }

    /// Build FTS5 query with prefix matching for instant search
    private func buildFTSQuery(_ input: String) -> String {
        let terms = input
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { term -> String in
                // Escape special FTS5 characters
                term.replacingOccurrences(of: "\"", with: "\"\"")
            }

        guard !terms.isEmpty else { return "" }

        // Add prefix operator to last term for instant-as-you-type search
        // "swift program" → "swift program*"
        guard let last = terms.last else { return "" }
        if terms.count == 1 {
            return "\(last)*"
        }

        let allButLast = terms.dropLast().joined(separator: " ")
        return "\(allButLast) \(last)*"
    }

    private func searchQuotes(_ ftsQuery: String) throws -> [SearchQuoteResult] {
        let sql = """
            SELECT
                quote_id,
                book_id,
                snippet(quotes_fts, 2, '<mark>', '</mark>', '...', 32) as snippet,
                bm25(quotes_fts, 0.0, 0.0, 1.0, 0.5, 0.5, 0.3) as rank
            FROM quotes_fts
            WHERE quotes_fts MATCH ?
            ORDER BY rank
            LIMIT 50
        """

        var results: [SearchQuoteResult] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, ftsQuery, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let quoteIdCStr = sqlite3_column_text(stmt, 0),
                  let bookIdCStr = sqlite3_column_text(stmt, 1),
                  let snippetCStr = sqlite3_column_text(stmt, 2),
                  let quoteId = UUID(uuidString: String(cString: quoteIdCStr)),
                  let bookId = UUID(uuidString: String(cString: bookIdCStr)) else {
                continue
            }

            let snippet = String(cString: snippetCStr)
            let rank = sqlite3_column_double(stmt, 3)

            results.append(SearchQuoteResult(
                quoteId: quoteId,
                bookId: bookId,
                snippet: snippet,
                rank: rank
            ))
        }

        return results
    }

    private func searchBooks(_ ftsQuery: String) throws -> [SearchBookResult] {
        let sql = """
            SELECT
                book_id,
                snippet(books_fts, 1, '<mark>', '</mark>', '...', 32) as title_snippet,
                snippet(books_fts, 2, '<mark>', '</mark>', '...', 32) as author_snippet,
                bm25(books_fts, 0.0, 1.0, 0.5, 0.3) as rank
            FROM books_fts
            WHERE books_fts MATCH ?
            ORDER BY rank
            LIMIT 20
        """

        var results: [SearchBookResult] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, ftsQuery, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let bookIdCStr = sqlite3_column_text(stmt, 0),
                  let titleCStr = sqlite3_column_text(stmt, 1),
                  let authorCStr = sqlite3_column_text(stmt, 2),
                  let bookId = UUID(uuidString: String(cString: bookIdCStr)) else {
                continue
            }

            let titleSnippet = String(cString: titleCStr)
            let authorSnippet = String(cString: authorCStr)
            let rank = sqlite3_column_double(stmt, 3)

            results.append(SearchBookResult(
                bookId: bookId,
                titleSnippet: titleSnippet,
                authorSnippet: authorSnippet,
                rank: rank
            ))
        }

        return results
    }

    // MARK: - Index Maintenance

    /// Index a quote for search
    func indexQuote(_ quote: Quote, book: Book) throws {
        // Delete old entry if exists
        try execute(
            "DELETE FROM quotes_fts WHERE quote_id = ?",
            params: [quote.id.uuidString]
        )

        // Insert new entry
        let sql = """
            INSERT INTO quotes_fts (quote_id, book_id, text, margin_note, book_title, book_author)
            VALUES (?, ?, ?, ?, ?, ?)
        """

        try execute(sql, params: [
            quote.id.uuidString,
            book.id.uuidString,
            quote.text,
            quote.marginNote ?? "",
            book.title,
            book.author
        ])
    }

    /// Index a book for search
    func indexBook(_ book: Book) throws {
        // Delete old entry if exists
        try execute(
            "DELETE FROM books_fts WHERE book_id = ?",
            params: [book.id.uuidString]
        )

        // Insert new entry
        let sql = """
            INSERT INTO books_fts (book_id, title, author, subtitle)
            VALUES (?, ?, ?, ?)
        """

        try execute(sql, params: [
            book.id.uuidString,
            book.title,
            book.author,
            book.subtitle ?? ""
        ])
    }

    /// Remove a quote from the index
    func removeQuote(id: UUID) throws {
        try execute(
            "DELETE FROM quotes_fts WHERE quote_id = ?",
            params: [id.uuidString]
        )
    }

    /// Remove a book from the index
    func removeBook(id: UUID) throws {
        try execute(
            "DELETE FROM books_fts WHERE book_id = ?",
            params: [id.uuidString]
        )
        // Also remove all quotes from this book
        try execute(
            "DELETE FROM quotes_fts WHERE book_id = ?",
            params: [id.uuidString]
        )
    }

    /// Rebuild entire index from scratch
    func rebuildIndex(books: [Book]) throws {
        try execute("DELETE FROM quotes_fts")
        try execute("DELETE FROM books_fts")

        for book in books {
            try indexBook(book)
            for quote in book.quotes {
                try indexQuote(quote, book: book)
            }
        }
    }

    // MARK: - SQL Execution Helpers

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw SearchError.queryFailed(message)
        }
    }

    private func execute(_ sql: String, params: [String]) throws {
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        for (index, param) in params.enumerated() {
            sqlite3_bind_text(
                stmt,
                Int32(index + 1),
                param,
                -1,
                unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            )
        }

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
    }

    private var lastErrorMessage: String {
        if let errorPointer = sqlite3_errmsg(db) {
            return String(cString: errorPointer)
        }
        return "Unknown SQLite error"
    }

    // MARK: - Statistics

    /// Get count of indexed quotes
    func quotesCount() throws -> Int {
        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM quotes_fts"

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return 0
        }

        return Int(sqlite3_column_int(stmt, 0))
    }

    /// Get count of indexed books
    func booksCount() throws -> Int {
        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM books_fts"

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return 0
        }

        return Int(sqlite3_column_int(stmt, 0))
    }

    // MARK: - Search Suggestions

    /// Find book titles matching a prefix
    func bookTitlesMatching(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let sql = """
            SELECT book_id, title, bm25(books_fts) as rank
            FROM books_fts
            WHERE title MATCH ?
            ORDER BY rank
            LIMIT ?
        """

        let ftsPrefix = "\(prefix)*"
        var results: [SearchSuggestion] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, ftsPrefix, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 2, Int32(limit))

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let bookIdCStr = sqlite3_column_text(stmt, 0),
                  let titleCStr = sqlite3_column_text(stmt, 1),
                  let bookId = UUID(uuidString: String(cString: bookIdCStr)) else {
                continue
            }

            let title = String(cString: titleCStr)
            results.append(.bookTitle(title, bookId))
        }

        return results
    }

    /// Find authors matching a prefix
    func authorsMatching(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let sql = """
            SELECT author, MIN(bm25(books_fts)) as rank
            FROM books_fts
            WHERE author MATCH ?
            GROUP BY author
            ORDER BY rank
            LIMIT ?
        """

        let ftsPrefix = "\(prefix)*"
        var results: [SearchSuggestion] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, ftsPrefix, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 2, Int32(limit))

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let authorCStr = sqlite3_column_text(stmt, 0) else {
                continue
            }

            let author = String(cString: authorCStr)
            if !author.isEmpty {
                results.append(.author(author))
            }
        }

        return results
    }

    /// Find popular terms matching a prefix from quote vocabulary
    func popularTermsMatching(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        // FTS5 vocabulary table provides term frequencies
        try createVocabTableIfNeeded()

        let sql = """
            SELECT term, cnt
            FROM quotes_fts_vocab
            WHERE term LIKE ?
            AND length(term) >= 3
            ORDER BY cnt DESC
            LIMIT ?
        """

        let likePattern = "\(prefix.lowercased())%"
        var results: [SearchSuggestion] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, likePattern, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 2, Int32(limit))

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let termCStr = sqlite3_column_text(stmt, 0) else {
                continue
            }

            let term = String(cString: termCStr)
            let count = Int(sqlite3_column_int(stmt, 1))
            results.append(.popularTerm(term, count))
        }

        return results
    }

    /// Create vocabulary table for term statistics
    private func createVocabTableIfNeeded() throws {
        let sql = """
            CREATE VIRTUAL TABLE IF NOT EXISTS quotes_fts_vocab USING fts5vocab(quotes_fts, row)
        """
        try execute(sql)
    }

    /// Check if a term exists in vocabulary
    func termExists(_ term: String) throws -> Bool {
        try createVocabTableIfNeeded()

        let sql = "SELECT 1 FROM quotes_fts_vocab WHERE term = ? LIMIT 1"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, term.lowercased(), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        return sqlite3_step(stmt) == SQLITE_ROW
    }

    /// Find closest matching term using edit distance approximation
    func closestTerm(to term: String) throws -> String? {
        try createVocabTableIfNeeded()

        let lowercasedTerm = term.lowercased()
        guard let firstChar = lowercasedTerm.first else { return nil }

        // Find terms starting with same letter and similar length
        let sql = """
            SELECT term
            FROM quotes_fts_vocab
            WHERE term LIKE ?
            AND length(term) BETWEEN ? AND ?
            ORDER BY cnt DESC
            LIMIT 10
        """

        var candidates: [(String, Int)] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw SearchError.queryFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        let likePattern = "\(firstChar)%"
        let minLength = max(1, lowercasedTerm.count - 2)
        let maxLength = lowercasedTerm.count + 2

        sqlite3_bind_text(stmt, 1, likePattern, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_int(stmt, 2, Int32(minLength))
        sqlite3_bind_int(stmt, 3, Int32(maxLength))

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let termCStr = sqlite3_column_text(stmt, 0) else {
                continue
            }

            let candidate = String(cString: termCStr)
            // Use global levenshteinDistance function from LevenshteinDistance.swift
            let distance = BookQuotes.levenshteinDistance(lowercasedTerm, candidate)
            candidates.append((candidate, distance))
        }

        // Return closest match if distance is reasonable
        if let best = candidates.min(by: { $0.1 < $1.1 }),
           best.1 <= 2 {
            return best.0
        }

        return nil
    }

    /// Suggest correction for likely typos
    func didYouMean(_ query: String) throws -> String? {
        let terms = query.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var corrections: [String] = []
        var hasCorrection = false

        for term in terms {
            let exists = try termExists(term)

            if !exists && term.count >= 4 {
                if let suggestion = try closestTerm(to: term) {
                    corrections.append(suggestion)
                    hasCorrection = true
                } else {
                    corrections.append(term)
                }
            } else {
                corrections.append(term)
            }
        }

        let corrected = corrections.joined(separator: " ")
        return hasCorrection ? corrected : nil
    }
}
