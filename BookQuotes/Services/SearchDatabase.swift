import Foundation
import SQLite3

// MARK: - SearchDatabase Actor

/// Actor managing SQLite FTS5 database for blazing-fast full-text search.
/// Uses porter stemming for word variations and BM25 for relevance ranking.
actor SearchDatabase {
    private let db: OpaquePointer

    // MARK: - Initialization

    /// Initialize with default path in documents directory
    init() throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = docs.appendingPathComponent("search_index.sqlite").path
        db = try Self.makeConfiguredDatabase(at: path)
    }

    /// Initialize an in-memory database (for tests).
    init(inMemory: Bool) throws {
        precondition(inMemory, "Use init() or init(path:) for on-disk databases")
        db = try Self.makeConfiguredDatabase(at: ":memory:")
    }

    /// Initialize with a custom path (for testing)
    init(path: URL) throws {
        db = try Self.makeConfiguredDatabase(at: path.path)
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup

    private static func makeConfiguredDatabase(at path: String) throws -> OpaquePointer {
        var connection: OpaquePointer?
        guard sqlite3_open(path, &connection) == SQLITE_OK, let connection else {
            if let connection {
                sqlite3_close(connection)
            }
            throw SearchError.databaseOpenFailed
        }

        do {
            try execute(SearchDatabaseSQL.createQuotesFTS, on: connection)
            try execute(SearchDatabaseSQL.createBooksFTS, on: connection)
            return connection
        } catch {
            sqlite3_close(connection)
            throw error
        }
    }

    private static func execute(_ sql: String, on connection: OpaquePointer) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(connection, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errorMessage)
            throw SearchError.queryFailed(message)
        }
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

    private func searchQuotes(_ ftsQuery: String) throws -> [SearchQuoteResult] {
        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.searchQuotes, errorMessage: lastErrorMessage)
        statement.bind(ftsQuery, at: 1)

        var results: [SearchQuoteResult] = []
        while statement.step() == SQLITE_ROW {
            guard let quoteIdText = statement.text(at: 0),
                  let bookIdText = statement.text(at: 1),
                  let snippet = statement.text(at: 2),
                  let quoteId = UUID(uuidString: quoteIdText),
                  let bookId = UUID(uuidString: bookIdText) else {
                continue
            }

            results.append(SearchQuoteResult(
                quoteId: quoteId,
                bookId: bookId,
                snippet: snippet,
                rank: statement.double(at: 3)
            ))
        }

        return results
    }

    private func searchBooks(_ ftsQuery: String) throws -> [SearchBookResult] {
        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.searchBooks, errorMessage: lastErrorMessage)
        statement.bind(ftsQuery, at: 1)

        var results: [SearchBookResult] = []
        while statement.step() == SQLITE_ROW {
            guard let bookIdText = statement.text(at: 0),
                  let titleSnippet = statement.text(at: 1),
                  let authorSnippet = statement.text(at: 2),
                  let bookId = UUID(uuidString: bookIdText) else {
                continue
            }

            results.append(SearchBookResult(
                bookId: bookId,
                titleSnippet: titleSnippet,
                authorSnippet: authorSnippet,
                rank: statement.double(at: 3)
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
        try execute(SearchDatabaseSQL.insertQuote, params: [
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
        try execute(SearchDatabaseSQL.insertBook, params: [
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
        try Self.execute(sql, on: db)
    }

    private func execute(_ sql: String, params: [String]) throws {
        let statement = try SQLiteStatement(database: db, sql: sql, errorMessage: lastErrorMessage)

        for (index, param) in params.enumerated() {
            statement.bind(param, at: Int32(index + 1))
        }

        guard statement.step() == SQLITE_DONE else {
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
        let sql = "SELECT COUNT(*) FROM quotes_fts"
        let statement = try SQLiteStatement(database: db, sql: sql, errorMessage: lastErrorMessage)
        guard statement.step() == SQLITE_ROW else {
            return 0
        }

        return statement.int(at: 0)
    }

    /// Get count of indexed books
    func booksCount() throws -> Int {
        let sql = "SELECT COUNT(*) FROM books_fts"
        let statement = try SQLiteStatement(database: db, sql: sql, errorMessage: lastErrorMessage)
        guard statement.step() == SQLITE_ROW else {
            return 0
        }

        return statement.int(at: 0)
    }

    // MARK: - Search Suggestions

    /// Find book titles matching a prefix
    func bookTitlesMatching(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let ftsPrefix = "\(prefix)*"
        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.bookTitleSuggestions, errorMessage: lastErrorMessage)
        statement.bind(ftsPrefix, at: 1)
        statement.bind(Int32(limit), at: 2)

        var results: [SearchSuggestion] = []
        while statement.step() == SQLITE_ROW {
            guard let bookIdText = statement.text(at: 0),
                  let title = statement.text(at: 1),
                  let bookId = UUID(uuidString: bookIdText) else {
                continue
            }

            results.append(.bookTitle(title, bookId))
        }

        return results
    }

    /// Find authors matching a prefix
    func authorsMatching(prefix: String, limit: Int) throws -> [SearchSuggestion] {
        let ftsPrefix = "\(prefix)*"
        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.authorSuggestions, errorMessage: lastErrorMessage)
        statement.bind(ftsPrefix, at: 1)
        statement.bind(Int32(limit), at: 2)

        var results: [SearchSuggestion] = []
        while statement.step() == SQLITE_ROW {
            guard let author = statement.text(at: 0) else {
                continue
            }

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

        let likePattern = "\(prefix.lowercased())%"
        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.popularTermSuggestions, errorMessage: lastErrorMessage)
        statement.bind(likePattern, at: 1)
        statement.bind(Int32(limit), at: 2)

        var results: [SearchSuggestion] = []
        while statement.step() == SQLITE_ROW {
            guard let term = statement.text(at: 0) else {
                continue
            }

            results.append(.popularTerm(term, statement.int(at: 1)))
        }

        return results
    }

    /// Create vocabulary table for term statistics
    private func createVocabTableIfNeeded() throws {
        try execute(SearchDatabaseSQL.createQuotesVocab)
    }

    /// Check if a term exists in vocabulary
    func termExists(_ term: String) throws -> Bool {
        try createVocabTableIfNeeded()

        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.termExists, errorMessage: lastErrorMessage)
        statement.bind(term.lowercased(), at: 1)

        return statement.step() == SQLITE_ROW
    }

    /// Find closest matching term using edit distance approximation
    func closestTerm(to term: String) throws -> String? {
        try createVocabTableIfNeeded()

        let lowercasedTerm = term.lowercased()
        guard let firstChar = lowercasedTerm.first else { return nil }

        var candidates: [(String, Int)] = []
        let statement = try SQLiteStatement(database: db, sql: SearchDatabaseSQL.closestTermCandidates, errorMessage: lastErrorMessage)

        let likePattern = "\(firstChar)%"
        let minLength = max(1, lowercasedTerm.count - 2)
        let maxLength = lowercasedTerm.count + 2

        statement.bind(likePattern, at: 1)
        statement.bind(Int32(minLength), at: 2)
        statement.bind(Int32(maxLength), at: 3)

        while statement.step() == SQLITE_ROW {
            guard let candidate = statement.text(at: 0) else {
                continue
            }

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
