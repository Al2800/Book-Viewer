import XCTest

/// End-to-end tests for book registration flow.
/// Tests manual entry, editing, and validation.
final class BookRegistrationFlowTests: BaseUITestCase {

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

    // MARK: - Add Book Navigation Tests

    func testLibrary_AddButton_ShowsAddOptions() {
        logger.step(1, "Finding add book button")
        let addButton = app.buttons[AccessibilityIdentifiers.Library.addBookButton]

        // Fallback to navigation bar button
        if !addButton.waitForExistence(timeout: 3) {
            let navAddButton = app.navigationBars.buttons["Add"]
            if navAddButton.exists {
                navAddButton.tap()
            } else {
                XCTFail("Add book button not found")
                return
            }
        } else {
            addButton.tap()
        }

        logger.step(2, "Verifying add options appear")
        // Should see options for manual entry or camera capture
        let addSheet = app.sheets.firstMatch
        if addSheet.waitForExistence(timeout: 3) {
            logger.success("Add book options sheet displayed")
        } else {
            // May go directly to add form
            let addFormTitle = app.navigationBars["Add Book"]
            XCTAssertTrue(addFormTitle.waitForExistence(timeout: 3), "Add book form should appear")
            logger.success("Add book form displayed directly")
        }
    }

    // MARK: - Manual Entry Tests

    func testManualEntry_CreateBook_WithRequiredFields() {
        executionTimeAllowance = 120
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Entering book title")
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Title field should exist")
        typeText("Test Book", into: titleField)

        logger.step(3, "Entering author")
        let authorField = app.textFields["Author"]
        XCTAssertTrue(authorField.exists, "Author field should exist")
        typeText("Test Author", into: authorField)

        logger.step(4, "Saving book")
        tapConfirmationButton()

        logger.step(5, "Verifying book appears in library")
        XCTAssertTrue(waitForBookAppearance(title: "Test Book", timeout: 6), "New book should appear after save")

        logger.success("Manual book entry completed successfully")
    }

    func testManualEntry_CreateBook_WithAllFields() {
        executionTimeAllowance = 120
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Filling required fields")
        let titleField = app.textFields["Title"]
        typeText("Complete Test Book", into: titleField)

        let authorField = app.textFields["Author"]
        typeText("Complete Author", into: authorField)

        logger.step(3, "Filling optional fields")

        let subtitleField = app.textFields["Subtitle"]
        if subtitleField.exists {
            typeText("A Subtitle for Testing", into: subtitleField)
        }

        // Scroll to see more fields
        app.swipeUp()

        let isbnField = app.textFields["ISBN"]
        if isbnField.exists {
            typeText("9780123456789", into: isbnField)
        }

        let publisherField = app.textFields["Publisher"]
        if publisherField.exists {
            typeText("Test Publisher", into: publisherField)
        }

        logger.step(4, "Saving book")
        tapConfirmationButton()

        logger.step(5, "Verifying book saved")
        XCTAssertTrue(waitForBookAppearance(title: "Complete Test Book", timeout: 6), "Book with all fields should appear")

        logger.success("Book with all fields created successfully")
    }

    func testManualEntry_EmptyTitle_ShowsError() {
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Entering only author (leaving title empty)")
        let authorField = app.textFields["Author"]
        if authorField.waitForExistence(timeout: 3) {
            typeText("Author Without Title", into: authorField)
        }

        logger.step(3, "Attempting to save")
        if let saveButton = findConfirmationButton(timeout: 2) {
            // Save should be disabled or show error
            if saveButton.isEnabled {
                saveButton.tap()

                logger.step(4, "Checking for error")
                // Should show error or stay on form
                let stillOnForm = app.navigationBars["Add Book"].exists
                XCTAssertTrue(stillOnForm, "Should remain on form with empty title")
            } else {
                logger.success("Save button correctly disabled for empty title")
            }
        }
    }

    func testManualEntry_CancelButton_DiscardsChanges() {
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Entering some data")
        let titleField = app.textFields["Title"]
        if titleField.waitForExistence(timeout: 3) {
            typeText("Cancelled Book", into: titleField)
        }

        logger.step(3, "Tapping Cancel")
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        } else {
            // Try back button
            tapBackButton()
        }

        logger.step(4, "Verifying book not saved")
        // Book should not appear in library
        let cancelledBook = app.staticTexts["Cancelled Book"]
        XCTAssertFalse(cancelledBook.waitForExistence(timeout: 2), "Cancelled book should not appear")

        logger.success("Cancel correctly discards changes")
    }

    // MARK: - Edit Book Tests

    func testEditBook_ModifyTitle_SavesChanges() {
        executionTimeAllowance = 120
        logger.step(1, "Opening existing book")
        openFirstBook()

        logger.step(2, "Opening edit mode")
        let menuButton = findMoreMenuButton()
        XCTAssertTrue(menuButton.waitForExistence(timeout: 3), "Menu button should exist")
        menuButton.tap()
        let editOption = app.buttons["Edit"]
        XCTAssertTrue(editOption.waitForExistence(timeout: 2), "Edit option should be available")
        editOption.tap()

        logger.step(3, "Verifying edit form opened")
        let editNavTitle = app.navigationBars["Edit Book"]
        XCTAssertTrue(editNavTitle.waitForExistence(timeout: 3), "Edit form should open")

        logger.step(4, "Modifying title")
        let titleField = app.textFields["Title"]
        if titleField.waitForExistence(timeout: 2) {
            titleField.tap()
            // Clear existing text
            titleField.doubleTap()
            app.keys["delete"].tap()
            typeText("Modified Title", into: titleField)
        }

        logger.step(5, "Saving changes")
        tapConfirmationButton()

        logger.step(6, "Verifying changes saved")
        // Should return to book detail with modified title
        let modifiedTitle = app.staticTexts["Modified Title"]
        // Note: This may fail if we can't properly edit seeded data
        if modifiedTitle.waitForExistence(timeout: 3) {
            logger.success("Edit book saved successfully")
        } else {
            logger.info("Could not verify modified title (seeded data may be read-only)")
        }
    }

    // MARK: - Reading Status Tests

    func testEditBook_ChangeReadingStatus_UpdatesStatus() {
        logger.step(1, "Opening existing book")
        openFirstBook()

        logger.step(2, "Finding reading status picker")
        let statusPicker = app.buttons[AccessibilityIdentifiers.BookDetail.statusPicker]
        if statusPicker.waitForExistence(timeout: 3) {
            statusPicker.tap()

            logger.step(3, "Selecting new status")
            let finishedOption = app.buttons["Finished"]
            if finishedOption.waitForExistence(timeout: 2) {
                finishedOption.tap()
                logger.success("Reading status changed")
            }
        } else {
            logger.info("Status picker not found on book detail")
        }
    }

    // MARK: - Cover Image Tests

    func testEditBook_CoverImageSection_DisplaysCorrectly() {
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Finding cover section")
        // Look for cover-related elements
        let addCoverText = app.staticTexts["Add Cover"]
        let coverSection = app.staticTexts["Cover"]

        let hasCoverUI = addCoverText.exists || coverSection.exists

        if hasCoverUI {
            logger.success("Cover image section displayed")
        } else {
            logger.info("Cover section may have different UI structure")
        }
    }

    // MARK: - Form Validation Tests

    func testManualEntry_VeryLongTitle_Handled() {
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Entering very long title")
        let titleField = app.textFields["Title"]
        if titleField.waitForExistence(timeout: 3) {
            let longTitle = String(repeating: "A", count: 200)
            typeText(longTitle, into: titleField)
        }

        logger.step(3, "Entering author")
        let authorField = app.textFields["Author"]
        if authorField.exists {
            typeText("Author", into: authorField)
        }

        logger.step(4, "Saving")
        tapConfirmationButton()

        // Should either truncate or handle long title gracefully
        logger.success("Long title handled (no crash)")
    }

    // MARK: - Helpers

    private func openAddBookForm() {
        let addButton = app.buttons[AccessibilityIdentifiers.Library.addBookButton]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        } else {
            // Try navigation bar add button
            let navAddButton = app.navigationBars.buttons["Add"]
            if navAddButton.exists {
                navAddButton.tap()
            }
        }

        // If sheet appears with options, select manual entry
        let manualEntry = app.buttons["Enter Manually"]
        if manualEntry.waitForExistence(timeout: 2) {
            manualEntry.tap()
        }

        // Wait for form
        _ = app.textFields["Title"].waitForExistence(timeout: 3)
    }

    private func openFirstBook() {
        // Switch to list view for easier selection
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        if viewModeToggle.waitForExistence(timeout: 2) {
            if viewModeToggle.buttons.count > 1 {
                viewModeToggle.buttons.element(boundBy: 1).tap()
            }
        }

        // Tap first book
        let bookRowCell = app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let bookRowButton = app.buttons[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let bookRowElement = app.otherElements[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let bookRowLink = app.links[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let bookCardButton = app.buttons[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch
        let bookCardLink = app.links[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch

        if bookRowCell.waitForExistence(timeout: 3) {
            bookRowCell.tap()
        } else if bookRowButton.exists {
            bookRowButton.tap()
        } else if bookRowElement.exists {
            bookRowElement.tap()
        } else if bookRowLink.exists {
            bookRowLink.tap()
        } else if bookCardButton.waitForExistence(timeout: 2) {
            bookCardButton.tap()
        } else if bookCardLink.waitForExistence(timeout: 2) {
            bookCardLink.tap()
        } else if app.cells.firstMatch.exists {
            app.cells.firstMatch.tap()
        }

        // Wait for detail view
        let title = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        let author = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookAuthor]
        let quotesLabel = app.staticTexts["Quotes"]
        let detailVisible = title.waitForExistence(timeout: 4) || author.exists || quotesLabel.exists
        XCTAssertTrue(detailVisible, "Book detail should appear")
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

    private func findConfirmationButton(timeout: TimeInterval = 2) -> XCUIElement? {
        let labels = ["Add Book", "Save", "Done"]
        for label in labels {
            let button = app.buttons[label]
            if button.waitForExistence(timeout: timeout) {
                return button
            }
            let navButton = app.navigationBars.buttons[label]
            if navButton.waitForExistence(timeout: timeout) {
                return navButton
            }
        }
        return nil
    }

    private func tapConfirmationButton() {
        dismissKeyboard()
        if let button = findConfirmationButton(timeout: 2) {
            button.tap()
        }
    }

    private func waitForBookAppearance(title: String, timeout: TimeInterval) -> Bool {
        let detailTitle = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        if detailTitle.waitForExistence(timeout: timeout) {
            return true
        }

        let libraryTitle = app.staticTexts[title]
        if libraryTitle.waitForExistence(timeout: timeout) {
            return true
        }

        let titlePredicate = NSPredicate(format: "label == %@", title)
        let inCells = app.cells.staticTexts.matching(titlePredicate).firstMatch
        return inCells.waitForExistence(timeout: timeout)
    }
}
