import XCTest

/// Tests for library management using seeded test data.
final class LibraryManagementTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()

        // Navigate to library tab
        let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    // MARK: - Library Display Tests

    func testLibrary_ShowsSeededBooks() {
        logger.step(1, "Verifying library has seeded books")

        // With seeded data, library should not be empty
        let emptyState = app.otherElements[AccessibilityIdentifiers.Library.emptyState]
        XCTAssertFalse(emptyState.exists, "Library should have seeded data, not empty state")

        logger.step(2, "Checking for book tiles")
        XCTAssertTrue(hasAnyBookTile(), "Should have book tiles from seeded data")

        logger.success("Library displays seeded books")
    }

    func testLibrary_DisplaysExpectedBookCount() {
        logger.step(1, "Counting books in library")

        // Seeded library should have exactly 3 books
        let bookCards = app.otherElements[AccessibilityIdentifiers.Library.bookCoverCard]
        let bookRows = app.cells[AccessibilityIdentifiers.Library.bookListRow]

        // Count from grid or list view
        let count = max(bookCards.count, bookRows.count)

        logger.step(2, "Verifying expected book count")
        XCTAssertEqual(count, UITestData.Counts.libraryBooks, "Should have \(UITestData.Counts.libraryBooks) seeded books")

        logger.success("Library has \(count) books as expected")
    }

    func testLibrary_TapBook_NavigatesToDetail() {
        logger.step(1, "Opening first book")
        openFirstBookDetail()

        logger.step(2, "Verifying book detail view")
        let quotesLabel = app.staticTexts["Quotes"]
        XCTAssertTrue(quotesLabel.waitForExistence(timeout: 3), "Should navigate to book detail")

        logger.success("Book detail view displayed")
    }

    func testLibrary_AtomicHabitsBook_Exists() {
        logger.step(1, "Looking for Atomic Habits book")

        // Search for the seeded book title
        let atomicHabits = app.staticTexts[UITestData.Books.atomicHabitsTitle]
        if !atomicHabits.exists {
            // Try scrolling to find it
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
            }
        }

        // Verify book exists in some form (title text or accessible element)
        let found = atomicHabits.waitForExistence(timeout: 3) ||
                    app.buttons.matching(NSPredicate(format: "label CONTAINS %@", UITestData.Books.atomicHabitsTitle)).count > 0

        XCTAssertTrue(found, "Seeded book 'Atomic Habits' should exist in library")

        logger.success("Found Atomic Habits book")
    }

    // MARK: - Book Editing Tests

    func testBookDetail_EditButton_Available() {
        logger.step(1, "Opening book detail")
        openFirstBookDetail()

        logger.step(2, "Opening menu")
        let menuButton = findMoreMenuButton()
        XCTAssertTrue(menuButton.waitForExistence(timeout: 3), "Menu button should exist")
        menuButton.tap()

        logger.step(3, "Checking for edit button")
        let editButton = app.buttons[AccessibilityIdentifiers.BookDetail.editButton]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit button should be available")

        logger.success("Edit button is available in menu")

        // Dismiss menu
        app.tap()
    }

    // MARK: - Export Tests

    func testBookDetail_ExportSheet_Available() {
        logger.step(1, "Opening book detail")
        openFirstBookDetail()

        logger.step(2, "Opening menu")
        let menuButton = findMoreMenuButton()
        XCTAssertTrue(menuButton.waitForExistence(timeout: 3), "Menu button should exist")
        menuButton.tap()

        logger.step(3, "Opening export sheet")
        let exportItem = app.buttons["Export Quotes"]
        XCTAssertTrue(exportItem.waitForExistence(timeout: 2), "Export option should be available")
        exportItem.tap()

        logger.step(4, "Verifying export sheet")
        let exportButton = app.buttons[AccessibilityIdentifiers.Export.exportButton]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export sheet should be displayed")

        logger.success("Export sheet displayed")
        app.swipeDown()
    }

    // MARK: - Deletion Tests

    func testLibrary_DeleteBook_ShowsConfirmation() {
        logger.step(1, "Switching to list view")
        switchToListViewIfPossible()

        logger.step(2, "Finding a book row")
        let firstCell = app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 3), "Should have book rows from seeded data")

        logger.step(3, "Swiping to delete")
        firstCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2), "Delete action should appear")
        deleteButton.tap()

        logger.step(4, "Verifying confirmation dialog")
        let confirm = app.buttons["Delete Book and All Quotes"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3), "Confirmation dialog should appear")
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.exists)
        cancel.tap()

        logger.success("Delete confirmation shown and cancelled")
    }

    // MARK: - Helpers

    private func isEmptyLibrary() -> Bool {
        let emptyState = app.otherElements[AccessibilityIdentifiers.Library.emptyState]
        return emptyState.exists || app.staticTexts["No Books Yet"].exists
    }

    private func hasAnyBookTile() -> Bool {
        // Check for book cards (grid) or book rows (list) using identifiers
        let bookCards = app.otherElements[AccessibilityIdentifiers.Library.bookCoverCard]
        let bookRows = app.cells[AccessibilityIdentifiers.Library.bookListRow]

        if bookCards.count > 0 || bookRows.count > 0 {
            return true
        }

        // Fallback to generic checks
        if app.tables.cells.count > 0 {
            return true
        }
        return app.scrollViews.buttons.count > 0
    }

    private func openFirstBookDetail() {
        // With seeded data, we expect books to exist
        switchToListViewIfPossible()

        // Try using accessibility identifier first
        let bookRow = app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        if bookRow.waitForExistence(timeout: 3) {
            bookRow.tap()
            return
        }

        // Fallback to generic table cells
        if app.tables.cells.firstMatch.exists {
            app.tables.cells.firstMatch.tap()
            return
        }

        // Try grid view buttons
        let gridButton = app.scrollViews.buttons.firstMatch
        if gridButton.waitForExistence(timeout: 2) {
            gridButton.tap()
        }
    }

    private func switchToListViewIfPossible() {
        // Use accessibility identifier for view mode toggle
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        if viewModeToggle.waitForExistence(timeout: 2) {
            // Second button is list view
            if viewModeToggle.buttons.count > 1 {
                viewModeToggle.buttons.element(boundBy: 1).tap()
            }
            return
        }

        // Fallback to generic segmented control
        let segmented = app.segmentedControls.firstMatch
        if segmented.exists && segmented.buttons.count > 1 {
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
