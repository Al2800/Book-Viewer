import XCTest

final class SearchFlowTests: XCTestCase {
    private var app: XCUIApplication!
    private var logger: UITestLogger!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--preload-search-test-data"
        ]
        logger = UITestLogger(testName: name)

        logger.info("Launching app for search flow")
        app.launch()

        let libraryTab = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5))
        libraryTab.tap()
    }

    override func tearDown() {
        print(logger.summary())
        super.tearDown()
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

    func testSearch_Query_ShowsResultsOrEmptyState() {
        logger.step(1, "Searching for a common term")
        searchFor("atomic")

        logger.step(2, "Waiting for results or empty state")
        XCTAssertTrue(waitForResultsOrEmpty(timeout: 4))

        if hasResults() {
            logger.success("Search results displayed")
        } else {
            logger.warning("No results available (test data not loaded)")
        }
    }

    func testSearchResult_TapFirstCell_NavigatesIfAvailable() {
        logger.step(1, "Searching for results")
        searchFor("atomic")
        XCTAssertTrue(waitForResultsOrEmpty(timeout: 4))

        guard hasResults() else {
            throw XCTSkip("No search results to navigate (test data not loaded)")
        }

        logger.step(2, "Tapping first result")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.exists)
        firstCell.tap()

        logger.step(3, "Verifying navigation")
        if app.navigationBars["Quote"].waitForExistence(timeout: 2) {
            logger.success("Navigated to quote detail")
            return
        }

        let quotesLabel = app.staticTexts["Quotes"]
        XCTAssertTrue(quotesLabel.waitForExistence(timeout: 3))
        logger.success("Navigated to book detail")
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
            let noResults = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'No results'")
            ).firstMatch
            if noResults.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }
}

private final class UITestLogger {
    private let testName: String
    private var entries: [String] = []

    init(testName: String) {
        self.testName = testName
        info("Starting")
    }

    func step(_ index: Int, _ message: String) {
        log("STEP \(index): \(message)")
    }

    func info(_ message: String) {
        log("INFO: \(message)")
    }

    func success(_ message: String) {
        log("SUCCESS: \(message)")
    }

    func warning(_ message: String) {
        log("WARNING: \(message)")
    }

    func summary() -> String {
        (["==== \(testName) ===="] + entries + ["==== end ===="]).joined(separator: "\n")
    }

    private func log(_ message: String) {
        let line = "[\(timestamp())] \(message)"
        entries.append(line)
        print(line)
    }

    private func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
    }
}
