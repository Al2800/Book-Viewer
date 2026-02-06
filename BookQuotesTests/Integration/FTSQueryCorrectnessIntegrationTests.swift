import XCTest

@testable import BookQuotes

// MARK: - FTSQueryCorrectnessIntegrationTests

/// Integration tests focused on query parsing/sanitization behavior for real user input.
@MainActor
final class FTSQueryCorrectnessIntegrationTests: FTS5TestCase {

    func testSearch_QueryWithHyphen_TreatedAsSeparator_NotOperator() async throws {
        logger.step(1, "Index a book with a hyphenated title")
        let book = TestFixtures.book { b in
            b.title = "Sci-Fi Classics"
            b.author = "Test Author"
        }
        try insertBook(book)
        try await indexBook(book)

        logger.step(2, "Search using the hyphenated query")
        // Prior behavior could be interpreted as `sci NOT fi` by the FTS query parser.
        let results = try await search("sci-fi", scope: .books)
        XCTAssertEqual(results.books.count, 1)
        XCTAssertEqual(results.books.first?.bookId, book.id)
    }

    func testSearch_QueryWithApostrophe_DoesNotThrow() async throws {
        logger.step(1, "Index a quote containing an apostrophe")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Don't break the search parser when users type punctuation."
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Search using an apostrophe")
        let results = try await search("don't", scope: .quotes)
        XCTAssertEqual(results.quotes.count, 1)
        XCTAssertEqual(results.quotes.first?.quoteId, quote.id)
    }

    func testSearch_PunctuationOnlyQuery_ReturnsEmptyWithoutError() async throws {
        logger.step(1, "Search with punctuation-only input")
        let results = try await search("--- ( ) \" \"", scope: .all)
        XCTAssertTrue(results.isEmpty)
    }

    func testSearch_SnippetContainsMarkTags_OnMatch() async throws {
        logger.step(1, "Index a quote and search for a term that should be highlighted")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Happiness comes from within."
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Search and verify snippet includes <mark> tags")
        let results = try await search("happ", scope: .quotes)
        XCTAssertEqual(results.quotes.count, 1)
        let snippet = results.quotes.first?.snippet ?? ""
        XCTAssertTrue(snippet.contains("<mark>") && snippet.contains("</mark>"))
    }
}

