import XCTest

/// Tests for the search functionality using seeded test data.
final class SearchFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-search-test-data"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()

        // Navigate to library tab
        let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    // MARK: - Search UI Tests

    func testSearchBar_TapToActivate_ShowsKeyboard() {
        logger.step(1, "Tapping search bar")
        let searchField = activateSearchField()
        searchField.tap()

        logger.step(2, "Verifying keyboard appears")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))

        logger.success("Search keyboard activated")
    }

    func testSearch_EmptyQuery_ShowsPrompt() {
        logger.step(1, "Activating search without query")
        _ = activateSearchField()

        logger.step(2, "Verifying empty search prompt")
        let prompt = app.staticTexts["Search your library"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 3))

        logger.success("Empty search prompt displayed")
    }

    func testSearch_NoResults_ShowsEmptyState() {
        logger.step(1, "Searching for nonexistent term")
        searchFor("xyzzy123nonexistent")

        logger.step(2, "Verifying no-results state")
        let noResults = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'No results'")
        ).firstMatch
        XCTAssertTrue(noResults.waitForExistence(timeout: 4))

        logger.success("No-results empty state displayed")
    }

    func testSearch_Scopes_Available() {
        logger.step(1, "Activating search")
        _ = activateSearchField()

        logger.step(2, "Checking search scope buttons")
        let allScope = app.buttons["All"]
        let booksScope = app.buttons["Books"]
        let quotesScope = app.buttons["Quotes"]

        XCTAssertTrue(allScope.waitForExistence(timeout: 3))
        XCTAssertTrue(booksScope.exists)
        XCTAssertTrue(quotesScope.exists)

        logger.success("Search scopes visible")
    }

    func testSearch_Query_ShowsResults() {
        logger.step(1, "Searching for seeded book title")
        searchFor(UITestData.SearchTokens.habits)

        logger.step(2, "Waiting for search results")
        XCTAssertTrue(waitForResultsOrEmpty(timeout: 5))

        logger.step(3, "Verifying results contain expected data")
        // Seeded data should always produce results
        XCTAssertTrue(hasResults(), "Search should return results for seeded data")

        logger.success("Search results displayed for '\(UITestData.SearchTokens.habits)'")
    }

    func testSearch_SeededQuote_ReturnsMatch() {
        logger.step(1, "Searching for known quote text")
        searchFor(UITestData.SearchTokens.improvement)

        logger.step(2, "Waiting for results")
        XCTAssertTrue(waitForResultsOrEmpty(timeout: 5))
        XCTAssertTrue(hasResults(), "Search should find seeded quote with 'improvement'")

        logger.success("Found seeded quote matching 'improvement'")
    }

    func testSearchResult_TapFirstCell_NavigatesToDetail() {
        logger.step(1, "Searching for seeded content")
        searchFor(UITestData.Books.atomicHabitsTitle)
        XCTAssertTrue(waitForResultsOrEmpty(timeout: 5))
        XCTAssertTrue(hasResults(), "Seeded search should return results")

        logger.step(2, "Tapping first result")
        let firstResult = app.cells[AccessibilityIdentifiers.Search.bookResultRow].firstMatch
        if !firstResult.exists {
            // Try quote result row if book row not found
            let quoteResult = app.cells[AccessibilityIdentifiers.Search.quoteResultRow].firstMatch
            XCTAssertTrue(quoteResult.waitForExistence(timeout: 2))
            quoteResult.tap()
        } else {
            firstResult.tap()
        }

        logger.step(3, "Verifying navigation to detail")
        // Should navigate to either book detail or quote detail
        let quotesLabel = app.staticTexts["Quotes"]
        let quoteNav = app.navigationBars["Quote"]
        let navigated = quotesLabel.waitForExistence(timeout: 3) || quoteNav.exists
        XCTAssertTrue(navigated, "Should navigate to detail view")

        logger.success("Navigated to detail view")
    }

    // MARK: - Helpers

    @discardableResult
    private func activateSearchField() -> XCUIElement {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        return searchField
    }

    private func searchFor(_ query: String) {
        let searchField = activateSearchField()
        searchField.typeText(query)
    }

    private func hasResults() -> Bool {
        return app.cells.count > 0 || hasResultsHeader()
    }

    private func hasResultsHeader() -> Bool {
        return app.staticTexts["Books"].exists || app.staticTexts["Quotes"].exists
    }

    private func waitForResultsOrEmpty(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if hasResults() {
                return true
            }
            // Check for no results state using accessibility identifier
            let noResults = app.otherElements[AccessibilityIdentifiers.Search.noResultsView]
            if noResults.exists {
                return true
            }
            // Also check for text-based no results
            let noResultsText = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'No results'")
            ).firstMatch
            if noResultsText.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }
}
