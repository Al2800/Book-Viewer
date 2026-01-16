import XCTest

@testable import BookQuotes

// MARK: - SearchResultsTests

final class SearchResultsTests: XCTestCase {

    func testSearchResultsEmpty() {
        let results = SearchResults.empty
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(results.totalCount, 0)
    }

    func testHighlightedSnippetStripsMarkup() {
        let result = SearchQuoteResult(
            quoteId: UUID(),
            bookId: UUID(),
            snippet: "<mark>Focus</mark> on systems",
            rank: 1.0
        )

        XCTAssertEqual(result.plainText, "Focus on systems")
        XCTAssertFalse(result.highlightedSnippet.characters.isEmpty)
    }

    func testBookSearchResultHighlights() {
        let result = SearchBookResult(
            bookId: UUID(),
            titleSnippet: "<mark>Atomic</mark> Habits",
            authorSnippet: "James <mark>Clear</mark>",
            rank: 2.0
        )

        XCTAssertFalse(result.highlightedTitle.characters.isEmpty)
        XCTAssertFalse(result.highlightedAuthor.characters.isEmpty)
    }

    func testSearchErrorDescriptions() {
        XCTAssertEqual(SearchError.databaseOpenFailed.errorDescription, "Failed to open search database")
        XCTAssertEqual(SearchError.tableCreationFailed.errorDescription, "Failed to create search tables")
        XCTAssertEqual(SearchError.queryFailed("oops").errorDescription, "Search query failed: oops")
        XCTAssertEqual(SearchError.indexingFailed("bad").errorDescription, "Indexing failed: bad")
    }
}
