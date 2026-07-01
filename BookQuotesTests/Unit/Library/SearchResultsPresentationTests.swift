import XCTest

@testable import BookQuotes

final class SearchResultsPresentationTests: XCTestCase {
    func testSectionVisibilityFollowsScopeAndCounts() {
        XCTAssertTrue(
            SearchResultsPresentation(scope: .all, bookCount: 1, quoteCount: 1).showsBooks
        )
        XCTAssertTrue(
            SearchResultsPresentation(scope: .all, bookCount: 1, quoteCount: 1).showsQuotes
        )
        XCTAssertTrue(
            SearchResultsPresentation(scope: .books, bookCount: 1, quoteCount: 1).showsBooks
        )
        XCTAssertFalse(
            SearchResultsPresentation(scope: .books, bookCount: 1, quoteCount: 1).showsQuotes
        )
        XCTAssertFalse(
            SearchResultsPresentation(scope: .quotes, bookCount: 1, quoteCount: 1).showsBooks
        )
        XCTAssertTrue(
            SearchResultsPresentation(scope: .quotes, bookCount: 1, quoteCount: 1).showsQuotes
        )
        XCTAssertFalse(
            SearchResultsPresentation(scope: .all, bookCount: 0, quoteCount: 1).showsBooks
        )
    }

    func testAnimationDelaysMatchExistingStaggeringContract() {
        let presentation = SearchResultsPresentation(scope: .all, bookCount: 10, quoteCount: 4)

        XCTAssertEqual(presentation.bookAnimationDelay(index: 0), 0)
        XCTAssertEqual(presentation.bookAnimationDelay(index: 9), 0.32, accuracy: 0.0001)
        XCTAssertEqual(presentation.quoteAnimationDelay(index: 0), 0.4, accuracy: 0.0001)
        XCTAssertEqual(presentation.quoteAnimationDelay(index: 4), 0.48, accuracy: 0.0001)
    }

    func testResultCountTransitionControlsAnimationReset() {
        XCTAssertTrue(SearchResultsPresentation.shouldResetResultsAnimation(oldCount: 0, newCount: 2))
        XCTAssertFalse(SearchResultsPresentation.shouldResetResultsAnimation(oldCount: 1, newCount: 2))
        XCTAssertFalse(SearchResultsPresentation.shouldResetResultsAnimation(oldCount: 0, newCount: 0))
    }

    func testDidYouMeanFetchOnlyWhenQueryHasNoResultsAndSearchIsIdle() {
        XCTAssertTrue(
            SearchResultsPresentation.shouldFetchDidYouMean(
                resultCount: 0,
                searchText: "habits",
                isSearching: false
            )
        )
        XCTAssertFalse(
            SearchResultsPresentation.shouldFetchDidYouMean(
                resultCount: 1,
                searchText: "habits",
                isSearching: false
            )
        )
        XCTAssertFalse(
            SearchResultsPresentation.shouldFetchDidYouMean(
                resultCount: 0,
                searchText: "",
                isSearching: false
            )
        )
        XCTAssertFalse(
            SearchResultsPresentation.shouldFetchDidYouMean(
                resultCount: 0,
                searchText: "habits",
                isSearching: true
            )
        )
    }
}
