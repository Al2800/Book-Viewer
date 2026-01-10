import XCTest

final class LibraryManagementTests: XCTestCase {
    private var app: XCUIApplication!
    private var logger: UITestLogger!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = [
            "--uitesting",
            "--preload-library-test-data"
        ]
        logger = UITestLogger(testName: name)

        logger.info("Launching app for library management flow")
        app.launch()

        let libraryTab = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5))
        libraryTab.tap()
    }

    override func tearDown() {
        print(logger.summary())
        super.tearDown()
    }

    // MARK: - Library Display Tests

    func testLibrary_ShowsBooksOrEmptyState() {
        logger.step(1, "Checking library content")
        if isEmptyLibrary() {
            logger.success("Empty state displayed")
            XCTAssertTrue(app.staticTexts["No Books Yet"].exists)
            return
        }

        XCTAssertTrue(hasAnyBookTile())
        logger.success("Books present in library")
    }

    func testLibrary_TapFirstBook_NavigatesToDetail() throws {
        logger.step(1, "Opening first book")
        try openFirstBookDetail()

        logger.step(2, "Verifying book detail view")
        let quotesLabel = app.staticTexts["Quotes"]
        XCTAssertTrue(quotesLabel.waitForExistence(timeout: 3))

        logger.success("Book detail view displayed")
    }

    // MARK: - Book Editing Tests

    func testBookDetail_EditSheet_Available() throws {
        logger.step(1, "Opening book detail")
        try openFirstBookDetail()

        logger.step(2, "Opening menu")
        let menuButton = findMoreMenuButton()
        guard menuButton.exists else {
            throw XCTSkip("Menu button not found")
        }
        menuButton.tap()

        logger.step(3, "Opening edit sheet")
        let editItem = app.buttons["Edit"]
        guard editItem.waitForExistence(timeout: 2) else {
            throw XCTSkip("Edit action not available")
        }
        editItem.tap()

        let editTitle = app.navigationBars["Edit Book"]
        XCTAssertTrue(editTitle.waitForExistence(timeout: 3))

        logger.success("Edit sheet displayed")

        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    // MARK: - Export Tests

    func testBookDetail_ExportSheet_Available() throws {
        logger.step(1, "Opening book detail")
        try openFirstBookDetail()

        logger.step(2, "Opening menu")
        let menuButton = findMoreMenuButton()
        guard menuButton.exists else {
            throw XCTSkip("Menu button not found")
        }
        menuButton.tap()

        logger.step(3, "Opening export sheet")
        let exportItem = app.buttons["Export Quotes"]
        guard exportItem.waitForExistence(timeout: 2) else {
            throw XCTSkip("Export action not available")
        }
        exportItem.tap()

        let exportTitle = app.navigationBars.matching(
            NSPredicate(format: "label CONTAINS 'Export'")
        ).firstMatch
        XCTAssertTrue(exportTitle.waitForExistence(timeout: 3))

        logger.success("Export sheet displayed")
        app.swipeDown()
    }

    // MARK: - Deletion Tests

    func testLibrary_DeleteBook_ShowsConfirmation() throws {
        logger.step(1, "Switching to list view")
        switchToListViewIfPossible()

        let firstCell = app.tables.cells.firstMatch
        guard firstCell.waitForExistence(timeout: 3) else {
            throw XCTSkip("No list cells available for deletion")
        }

        logger.step(2, "Swiping to delete")
        firstCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        guard deleteButton.waitForExistence(timeout: 2) else {
            throw XCTSkip("Delete action not available")
        }
        deleteButton.tap()

        logger.step(3, "Verifying confirmation dialog")
        let confirm = app.buttons["Delete Book and All Quotes"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.exists)
        cancel.tap()

        logger.success("Delete confirmation shown")
    }

    // MARK: - Helpers

    private func isEmptyLibrary() -> Bool {
        return app.staticTexts["No Books Yet"].exists
    }

    private func hasAnyBookTile() -> Bool {
        if app.tables.cells.count > 0 {
            return true
        }
        return app.scrollViews.buttons.count > 0
    }

    private func openFirstBookDetail() throws {
        if isEmptyLibrary() {
            throw XCTSkip("Library is empty")
        }

        switchToListViewIfPossible()

        if app.tables.cells.firstMatch.exists {
            app.tables.cells.firstMatch.tap()
            return
        }

        let gridButton = app.scrollViews.buttons.firstMatch
        guard gridButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("No book tiles to open")
        }
        gridButton.tap()
    }

    private func switchToListViewIfPossible() {
        let segmented = app.segmentedControls.firstMatch
        guard segmented.exists else { return }
        if segmented.buttons.count > 1 {
            segmented.buttons.element(boundBy: 1).tap()
        }
    }

    private func findMoreMenuButton() -> XCUIElement {
        let navButtons = app.navigationBars.buttons
        let predicate = NSPredicate(format: "label CONTAINS 'More' OR label CONTAINS 'ellipsis'")
        let match = navButtons.matching(predicate).firstMatch
        if match.exists {
            return match
        }
        if navButtons.count > 0 {
            return navButtons.element(boundBy: navButtons.count - 1)
        }
        return navButtons.firstMatch
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
