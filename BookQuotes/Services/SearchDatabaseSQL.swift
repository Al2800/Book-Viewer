enum SearchDatabaseSQL {
    static let createQuotesFTS = """
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

    static let createBooksFTS = """
        CREATE VIRTUAL TABLE IF NOT EXISTS books_fts USING fts5(
            book_id UNINDEXED,
            title,
            author,
            subtitle,
            tokenize='porter unicode61'
        );
    """

    static let createQuotesVocab = """
        CREATE VIRTUAL TABLE IF NOT EXISTS quotes_fts_vocab USING fts5vocab(quotes_fts, row)
    """

    static let searchQuotes = """
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

    static let searchBooks = """
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

    static let insertQuote = """
        INSERT INTO quotes_fts (quote_id, book_id, text, margin_note, book_title, book_author)
        VALUES (?, ?, ?, ?, ?, ?)
    """

    static let insertBook = """
        INSERT INTO books_fts (book_id, title, author, subtitle)
        VALUES (?, ?, ?, ?)
    """

    static let bookTitleSuggestions = """
        SELECT book_id, title, bm25(books_fts) as rank
        FROM books_fts
        WHERE title MATCH ?
        ORDER BY rank
        LIMIT ?
    """

    static let authorSuggestions = """
        SELECT author, MIN(bm25(books_fts)) as rank
        FROM books_fts
        WHERE author MATCH ?
        GROUP BY author
        ORDER BY rank
        LIMIT ?
    """

    static let popularTermSuggestions = """
        SELECT term, cnt
        FROM quotes_fts_vocab
        WHERE term LIKE ?
        AND length(term) >= 3
        ORDER BY cnt DESC
        LIMIT ?
    """

    static let termExists = "SELECT 1 FROM quotes_fts_vocab WHERE term = ? LIMIT 1"

    static let closestTermCandidates = """
        SELECT term
        FROM quotes_fts_vocab
        WHERE term LIKE ?
        AND length(term) BETWEEN ? AND ?
        ORDER BY cnt DESC
        LIMIT 10
    """
}
