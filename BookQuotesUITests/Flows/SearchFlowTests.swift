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
        let libraryTab = tabButton(.library)
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
        let searchField = activateSearchField()

        logger.step(2, "Verifying empty search prompt")
        let prompt = app.staticTexts["Search your library"]
        let placeholder = app.searchFields["Search books and quotes"]
        let searchValue = (searchField.value as? String) ?? ""
        let hasPrompt = prompt.waitForExistence(timeout: 3) ||
            placeholder.exists ||
            searchValue.lowercased().contains("search")
        XCTAssertTrue(hasPrompt)

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
        let bookButton = app.buttons[AccessibilityIdentifiers.Search.bookResultRow].firstMatch
        let bookCell = app.cells[AccessibilityIdentifiers.Search.bookResultRow].firstMatch
        let bookRow = app.otherElements[AccessibilityIdentifiers.Search.bookResultRow].firstMatch

        if tapFirstHittable([bookButton, bookCell, bookRow]) {
            logger.info("Tapped book result row")
        } else {
            let quoteButton = app.buttons[AccessibilityIdentifiers.Search.quoteResultRow].firstMatch
            let quoteCell = app.cells[AccessibilityIdentifiers.Search.quoteResultRow].firstMatch
            let quoteRow = app.otherElements[AccessibilityIdentifiers.Search.quoteResultRow].firstMatch
            XCTAssertTrue(quoteButton.waitForExistence(timeout: 2) || quoteCell.exists || quoteRow.exists)
            XCTAssertTrue(tapFirstHittable([quoteButton, quoteCell, quoteRow]))
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
        let bookButtons = app.buttons.matching(identifier: AccessibilityIdentifiers.Search.bookResultRow)
        let quoteButtons = app.buttons.matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)
        let bookRows = app.otherElements.matching(identifier: AccessibilityIdentifiers.Search.bookResultRow)
        let quoteRows = app.otherElements.matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)
        return app.cells.count > 0 ||
            bookButtons.count > 0 ||
            quoteButtons.count > 0 ||
            bookRows.count > 0 ||
            quoteRows.count > 0 ||
            hasResultsHeader()
    }

    private func hasResultsHeader() -> Bool {
        return app.staticTexts["Books"].exists || app.staticTexts["Quotes"].exists
    }

    private func waitForResultsOrEmpty(timeout: TimeInterval) -> Bool {
        return waitUntil("search results or empty state", timeout: timeout) { [weak self] in
            guard let self else { return false }
            if self.hasResults() { return true }

            let noResults = self.app.otherElements[AccessibilityIdentifiers.Search.noResultsView]
            if noResults.exists { return true }

            let noResultsText = self.app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'No results'")
            ).firstMatch
            return noResultsText.exists
        }
    }

    private func tapFirstHittable(_ elements: [XCUIElement]) -> Bool {
        for element in elements where element.exists && element.isHittable {
            element.tap()
            return true
        }

        for element in elements where element.exists {
            let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
            return true
        }

        return false
    }
}

/// Regression coverage for Search and quote detail at the largest supported text size.
final class AdaptiveSearchAndQuoteDetailLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        XCTAssertTrue(tapTab(.library), "Library tab should be available")
    }

    func testSearchAndQuoteEditorRemainReachableWithAccessibilityText() {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search should be available")
        XCTAssertTrue(searchField.isHittable, "Search should remain reachable")
        searchField.tap()
        app.typeText(UITestData.SearchTokens.improvement)

        let quoteResult = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Search.quoteResultRow)
            .firstMatch
        XCTAssertTrue(quoteResult.waitForExistence(timeout: 8), "Seeded quote search should return a quote row")
        XCTAssertTrue(reveal(quoteResult), "Quote result should remain reachable")
        captureScreenshot(named: "accessibility_text_search", description: "Quote search at accessibility text size")
        quoteResult.tap()

        let favorite = app.buttons[AccessibilityIdentifiers.QuoteDetail.favoriteButton]
        XCTAssertTrue(favorite.waitForExistence(timeout: 6), "Quote detail should open from search")
        XCTAssertTrue(favorite.isHittable, "Quote detail favorite control should remain reachable")

        let moreMenu = app.buttons[AccessibilityIdentifiers.Common.moreMenuButton]
        XCTAssertTrue(moreMenu.waitForExistence(timeout: 5), "Quote detail should expose its actions")
        moreMenu.tap()

        let edit = app.buttons["Edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5), "Quote detail should offer editing")
        edit.tap()

        let editor = app.textViews[AccessibilityIdentifiers.QuoteDetail.textEditor]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "Quote editor should open")
        XCTAssertTrue(reveal(editor), "Quote editor should remain reachable")
    }

    private func reveal(_ element: XCUIElement) -> Bool {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}

/// Smoke coverage for the default-off v2 product shell.
final class V2ProductShellTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-search-test-data",
            "--product-experience-v2"
        ]
    }

    func testV2ShellExposesReadingCaptureAndExplore() {
        let reading = app.buttons["v2_reading_tab"]
        let capture = app.buttons["v2_capture_tab"]
        let explore = app.buttons["v2_explore_tab"]

        XCTAssertTrue(reading.waitForExistence(timeout: 5), "Reading should be the first v2 destination")
        XCTAssertTrue(capture.exists, "Capture should remain a primary destination")
        XCTAssertTrue(explore.exists, "Explore should be a primary destination")
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Tabs.studioTab].exists, "Studio should not remain a primary v2 tab")

        explore.tap()

        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.searchFields["Search passages, books and notes"].exists)
        XCTAssertTrue(app.buttons["v2_settings_button"].exists, "Settings should remain reachable as a secondary action")
    }
}
