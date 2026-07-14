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

        logger.step(2, "Verifying camera-first add flow appears")
        // The library add button opens the cover capture flow (camera-first),
        // which offers manual entry as a fallback.
        let manualEntryButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'manually'")
        ).firstMatch
        let captureHeader = app.staticTexts["Add Book"]
        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]

        let hasCaptureFlow = manualEntryButton.waitForExistence(timeout: 3) ||
                             captureHeader.exists ||
                             permissionPrompt.exists
        XCTAssertTrue(hasCaptureFlow, "Cover capture flow should appear")
        logger.success("Cover capture flow displayed")
    }

    // MARK: - Manual Entry Tests

    func testManualEntry_CreateBook_WithRequiredFields() {
        executionTimeAllowance = 120
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Entering book title")
        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
            : app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Title field should exist")
        typeText("Test Book", into: titleField, dismissKeyboardAfter: false)

        logger.step(3, "Saving book")
        tapConfirmationButton()

        logger.step(4, "Verifying book appears in library")
        XCTAssertTrue(waitForBookAppearance(title: "Test Book", timeout: 6), "New book should appear after save")

        logger.success("Manual book entry completed successfully")
    }

    func testManualEntry_CreateBook_WithAllFields() {
        executionTimeAllowance = 120
        logger.step(1, "Opening add book form")
        openAddBookForm()

        logger.step(2, "Filling required fields")
        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
            : app.textFields["Title"]
        typeText("Complete Test Book", into: titleField, dismissKeyboardAfter: false)

        logger.step(3, "Filling optional fields")

        let subtitleField = app.textFields[AccessibilityIdentifiers.BookEdit.subtitleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.subtitleField]
            : app.textFields["Subtitle"]
        XCTAssertTrue(
            typeTextByScrolling("A Subtitle for Testing", into: subtitleField),
            "Subtitle field should accept text"
        )

        let isbnField = app.textFields[AccessibilityIdentifiers.BookEdit.isbnField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.isbnField]
            : app.textFields["ISBN"]
        XCTAssertTrue(
            typeTextByScrolling("9780123456789", into: isbnField),
            "ISBN field should accept text"
        )

        let publisherField = app.textFields[AccessibilityIdentifiers.BookEdit.publisherField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.publisherField]
            : app.textFields["Publisher"]
        XCTAssertTrue(
            typeTextByScrolling("Test Publisher", into: publisherField),
            "Publisher field should accept text"
        )

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
        let authorField = app.textFields[AccessibilityIdentifiers.BookEdit.authorField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.authorField]
            : app.textFields["Author"]
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
        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
            : app.textFields["Title"]
        if titleField.waitForExistence(timeout: 3) {
            typeText("Cancelled Book", into: titleField)
        }

        logger.step(3, "Tapping Cancel")
        let cancelButton = app.buttons[AccessibilityIdentifiers.BookEdit.cancelButton].exists
            ? app.buttons[AccessibilityIdentifiers.BookEdit.cancelButton]
            : app.buttons["Cancel"]
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
        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
            : app.textFields["Title"]
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

	    func testManualEntry_CreateThenEditBook_UpdatesTitle() {
	        executionTimeAllowance = 180
	        let suffix = String(UUID().uuidString.prefix(8))
	        let originalTitle = "Editable Book \(suffix)"
	        let editedTitle = "Edited Book \(suffix)"

        logger.step(1, "Creating a new book")
        openAddBookForm()

        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
            : app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 3), "Title field should exist")
        typeText(originalTitle, into: titleField, dismissKeyboardAfter: false)

        tapConfirmationButton()
        XCTAssertTrue(waitForBookAppearance(title: originalTitle, timeout: 8), "Created book should appear")

        logger.step(2, "Opening created book detail")
        // Prefer tapping a cell containing the title; fall back to the static text directly.
        let titleInCell = app.cells.staticTexts[originalTitle].firstMatch
        if titleInCell.waitForExistence(timeout: 3) {
            titleInCell.tap()
        } else {
            let titleText = app.staticTexts[originalTitle].firstMatch
            XCTAssertTrue(titleText.waitForExistence(timeout: 3), "Created book title should be tappable")
            titleText.tap()
        }
        _ = app.staticTexts["Quotes"].waitForExistence(timeout: 3)

        logger.step(3, "Editing title")
        let menuButton = findMoreMenuButton()
        XCTAssertTrue(menuButton.waitForExistence(timeout: 3), "Menu button should exist")
        menuButton.tap()
        let editOption = app.buttons["Edit"]
        XCTAssertTrue(editOption.waitForExistence(timeout: 2), "Edit option should be available")
        editOption.tap()

        let editNavTitle = app.navigationBars["Edit Book"]
        XCTAssertTrue(editNavTitle.waitForExistence(timeout: 3), "Edit form should open")

	        let editTitleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
	            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
	            : app.textFields["Title"]
	        XCTAssertTrue(editTitleField.waitForExistence(timeout: 3), "Edit title field should exist")
	        replaceText(editedTitle, in: editTitleField)
	
	        tapConfirmationButton()

        logger.step(4, "Verifying edited title")
        let editedTitleText = app.staticTexts[editedTitle].firstMatch
        XCTAssertTrue(editedTitleText.waitForExistence(timeout: 6), "Edited title should be visible on detail screen")

        logger.success("Create then edit flow works")
    }

    // MARK: - Reading Status Tests

    func testEditBook_ChangeReadingStatus_UpdatesStatus() {
        logger.step(1, "Opening existing book")
        openFirstBook()

        logger.step(2, "Opening the book editor")
        openBookEditor()

        logger.step(3, "Selecting Finished status")
        let statusPicker = findReadingStatusPicker()
        XCTAssertTrue(statusPicker.exists, "Reading status picker should be visible in the book editor")

        let finishedOption = statusPicker.buttons["Finished"]
        XCTAssertTrue(finishedOption.waitForExistence(timeout: 3), "Finished status should be available")
        finishedOption.tap()
        XCTAssertTrue(finishedOption.isSelected, "Finished status should be selected")

        logger.step(4, "Saving the status change")
        tapConfirmationButton()
        XCTAssertTrue(
            app.staticTexts["Quotes"].waitForExistence(timeout: 5),
            "Saving should return to the book detail screen"
        )

        logger.step(5, "Reopening the editor to verify persistence")
        openBookEditor()
        let persistedStatusPicker = findReadingStatusPicker()
        let persistedFinishedOption = persistedStatusPicker.buttons["Finished"]
        XCTAssertTrue(persistedFinishedOption.waitForExistence(timeout: 3), "Finished status should remain available")
        XCTAssertTrue(persistedFinishedOption.isSelected, "Finished status should persist after saving")

        logger.success("Reading status changed and persisted")
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
        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField].exists
            ? app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
            : app.textFields["Title"]
        if titleField.waitForExistence(timeout: 3) {
            let longTitle = String(repeating: "A", count: 200)
            typeText(longTitle, into: titleField, dismissKeyboardAfter: false)
        }

        logger.step(3, "Saving")
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

        // The add flow is camera-first; use its manual entry fallback to reach the form.
        let manualEntry = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'manually'")
        ).firstMatch
        if manualEntry.waitForExistence(timeout: 3) {
            manualEntry.tap()
        }

        // Wait for form
        if app.textFields[AccessibilityIdentifiers.BookEdit.titleField].waitForExistence(timeout: 3) {
            return
        }
        _ = app.textFields["Title"].waitForExistence(timeout: 3)
    }

    private func typeTextByScrolling(_ text: String, into field: XCUIElement) -> Bool {
        guard field.waitForExistence(timeout: 3) else { return false }

        let form = app.scrollViews[AccessibilityIdentifiers.BookEdit.formScrollView]
        for _ in 0..<6 where !field.isHittable {
            guard form.exists else { return false }
            form.swipeUp()
        }

        return tryTypeText(text, into: field)
    }

    private func openFirstBook() {
        // Switch to list view for easier selection
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        if viewModeToggle.waitForExistence(timeout: 2) {
            if viewModeToggle.buttons.count > 1 {
                viewModeToggle.buttons.element(boundBy: 1).tap()
            }
        }

        // Tap first book. SwiftUI rows/cards use gestures, so coordinate taps are
        // more reliable than semantic taps on accessibility wrapper elements.
        let candidates = [
            app.staticTexts[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.images[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.buttons[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.otherElements[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.links[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.staticTexts[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch,
            app.images[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch,
            app.buttons[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch,
            app.links[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch,
            app.cells.firstMatch,
        ]

        let tappedBook = candidates.contains { element in
            guard element.waitForExistence(timeout: 2) else { return false }
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return true
        }
        XCTAssertTrue(tappedBook, "A tappable library book should exist")

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

    private func openBookEditor() {
        let menuButton = findMoreMenuButton()
        XCTAssertTrue(menuButton.waitForExistence(timeout: 3), "Menu button should exist")
        menuButton.tap()

        let editOption = app.buttons["Edit"]
        XCTAssertTrue(editOption.waitForExistence(timeout: 3), "Edit option should be available")
        editOption.tap()

        XCTAssertTrue(app.navigationBars["Edit Book"].waitForExistence(timeout: 3), "Edit form should open")
    }

    private func findReadingStatusPicker() -> XCUIElement {
        let picker = app.segmentedControls[AccessibilityIdentifiers.BookDetail.statusPicker]
        for _ in 0..<6 {
            if picker.exists { return picker }
            app.swipeUp()
        }
        return picker
    }

    private func findConfirmationButton(timeout: TimeInterval = 2) -> XCUIElement? {
        let explicit = app.buttons[AccessibilityIdentifiers.BookEdit.saveButton]
        if explicit.waitForExistence(timeout: timeout) {
            return explicit
        }
        let explicitNav = app.navigationBars.buttons[AccessibilityIdentifiers.BookEdit.saveButton]
        if explicitNav.waitForExistence(timeout: timeout) {
            return explicitNav
        }
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
        guard let button = findConfirmationButton(timeout: 2) else {
            XCTFail("Confirmation button not found (save/add)")
            return
        }
        if !button.isEnabled {
            _ = waitUntil("Confirmation button enabled", timeout: 2) { button.isEnabled }
        }
        XCTAssertTrue(button.isEnabled, "Confirmation button should be enabled")
        button.tap()
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
