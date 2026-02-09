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
        let libraryTab = tabButton(.library)
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

        // Prefer the test-only count marker for reliability across element types
        let bookCountLabel = app.staticTexts[AccessibilityIdentifiers.Common.uiTestBookCount]
        if bookCountLabel.waitForExistence(timeout: 2),
           let count = Int(bookCountLabel.label) {
            logger.step(2, "Verifying expected book count")
            XCTAssertEqual(count, UITestData.Counts.libraryBooks, "Should have \(UITestData.Counts.libraryBooks) seeded books")
            logger.success("Library has \(count) books as expected")
            return
        }

        // Fallback: count from grid or list view
        let bookElements = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookCoverCard)
        let rowElements = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookListRow)
        let count = max(bookElements.count, rowElements.count)

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
                    app.buttons.matching(NSPredicate(format: "label CONTAINS %@", UITestData.Books.atomicHabitsTitle)).count > 0 ||
                    app.links.matching(NSPredicate(format: "label CONTAINS %@", UITestData.Books.atomicHabitsTitle)).count > 0

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

        logger.step(5, "Verifying preview text exists")
        let previewText = app.staticTexts[AccessibilityIdentifiers.Export.previewText]
        let previewFallback = app.otherElements[AccessibilityIdentifiers.Export.previewText]
        XCTAssertTrue(
            previewText.waitForExistence(timeout: 3) || previewFallback.waitForExistence(timeout: 1),
            "Export preview text should be visible"
        )

        logger.step(6, "Switching format to JSON and verifying preview updates")
        switchExportFormat(to: "JSON")
        let jsonPreview = previewText.exists ? previewText.label : previewFallback.label
        XCTAssertTrue(
            jsonPreview.contains("{") || jsonPreview.contains("\"text\""),
            "JSON preview should look like JSON (got: \(jsonPreview.prefix(60)))"
        )

        logger.step(7, "Switching format back to Markdown and verifying preview updates")
        switchExportFormat(to: "Markdown")
        let mdPreview = previewText.exists ? previewText.label : previewFallback.label
        XCTAssertTrue(
            mdPreview.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(">"),
            "Markdown preview should start with '>' (got: \(mdPreview.prefix(60)))"
        )

        logger.success("Export sheet displayed")
        app.swipeDown()
    }

    private func switchExportFormat(to formatLabel: String) {
        let pickerButton = app.buttons[AccessibilityIdentifiers.Export.formatPicker]
        let pickerOther = app.otherElements[AccessibilityIdentifiers.Export.formatPicker]

        if pickerButton.waitForExistence(timeout: 2) {
            pickerButton.tap()
        } else if pickerOther.waitForExistence(timeout: 2) {
            pickerOther.tap()
        } else {
            XCTFail("Export format picker not found")
            return
        }

        // Menu picker presents options as buttons in a popover/sheet.
        let option = app.buttons[formatLabel]
        XCTAssertTrue(option.waitForExistence(timeout: 2), "Export format option '\(formatLabel)' should appear")
        option.tap()

        // Dismiss any transient popover by tapping somewhere safe.
        app.tap()
    }

    // MARK: - Deletion Tests

    func testLibrary_DeleteBook_ShowsConfirmation() throws {
        logger.step(1, "Switching to list view")
        switchToListViewIfPossible()

        logger.step(2, "Finding a book row")
        let firstCell = app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let firstLink = app.links[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let firstElement = app.otherElements[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        guard firstCell.waitForExistence(timeout: 3) ||
              firstLink.waitForExistence(timeout: 3) ||
              firstElement.waitForExistence(timeout: 3) else {
            throw XCTSkip("List rows unavailable for delete swipe")
        }
        let swipeTarget = firstCell.exists ? firstCell : (firstLink.exists ? firstLink : firstElement)

        logger.step(3, "Swiping to delete")
        swipeTarget.swipeLeft()
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
        let bookCountLabel = app.staticTexts[AccessibilityIdentifiers.Common.uiTestBookCount]
        if bookCountLabel.exists, (Int(bookCountLabel.label) ?? 0) > 0 {
            return true
        }

        let bookElements = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookCoverCard)
        let rowElements = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookListRow)

        if bookElements.count > 0 || rowElements.count > 0 {
            return true
        }

        // Fallback to generic checks
        if app.tables.cells.count > 0 {
            return true
        }
        return app.scrollViews.buttons.count > 0 || app.scrollViews.links.count > 0
    }

    private func openFirstBookDetail() {
        // With seeded data, we expect books to exist
        switchToListViewIfPossible()

        // Try using accessibility identifier first
        let bookRowElement = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookListRow)
            .firstMatch
        if bookRowElement.waitForExistence(timeout: 3) {
            bookRowElement.tap()
            return
        }

        let bookElement = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Library.bookCoverCard)
            .firstMatch
        if bookElement.waitForExistence(timeout: 3) {
            bookElement.tap()
            return
        }

        // Fallback to generic table cells
        if app.tables.cells.firstMatch.exists {
            app.tables.cells.firstMatch.tap()
            return
        }

        // Try grid view buttons
        let gridButton = app.scrollViews.buttons.firstMatch
        let gridLink = app.scrollViews.links.firstMatch
        if gridButton.waitForExistence(timeout: 2) {
            gridButton.tap()
        } else if gridLink.waitForExistence(timeout: 2) {
            gridLink.tap()
        }

        let title = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        let author = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookAuthor]
        let quotesLabel = app.staticTexts["Quotes"]
        _ = title.waitForExistence(timeout: 4) || author.exists || quotesLabel.exists
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
        let explicitButton = app.buttons[AccessibilityIdentifiers.Common.moreMenuButton]
        if explicitButton.exists {
            return explicitButton
        }
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
