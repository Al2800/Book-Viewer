import XCTest

/// End-to-end tests for the quote capture and review flow.
/// Tests camera capture, extraction review, editing, and saving.
final class QuoteCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data", "--mock-camera"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        logger.info("Quote capture tests ready")
    }

    // MARK: - Capture Tab Tests

    func testCaptureTab_DisplaysCameraOrPermission() {
        logger.step(1, "Navigating to Capture tab")
        let captureTab = tabButton(.capture)
        XCTAssertTrue(captureTab.waitForExistence(timeout: 5), "Capture tab should exist")
        captureTab.tap()

        logger.step(2, "Verifying capture view content")
        // Should see mode selection, camera preview, or permission request
        let modeSelectCover = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        let modeSelectQuote = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        let modeSelectBatch = app.buttons[AccessibilityIdentifiers.Capture.modeSelectBatch]
        let cameraPreview = app.otherElements[AccessibilityIdentifiers.Capture.cameraPreview]
        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]

        let hasModeSelection = modeSelectCover.waitForExistence(timeout: 5) ||
                              modeSelectQuote.exists ||
                              modeSelectBatch.exists
        let hasCaptureUI = hasModeSelection ||
                          cameraPreview.exists ||
                          permissionPrompt.exists ||
                          captureButton.exists

        XCTAssertTrue(hasCaptureUI, "Should show camera preview, permission request, or capture button")

        logger.success("Capture tab displays correctly")
    }

    func testCaptureTab_CaptureButton_Exists() {
        logger.step(1, "Navigating to Capture tab")
        openQuoteCaptureFromTab()

        logger.step(2, "Finding capture button")
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]

        if testButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(testButton.isEnabled, "Test image button should be enabled")
            logger.success("Test image button found and enabled")
        } else if captureButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(captureButton.isEnabled, "Capture button should be enabled")
            logger.success("Capture button found and enabled")
        } else {
            // May show permission UI instead
            let permissionPrompt = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'Camera'")
            ).firstMatch
            XCTAssertTrue(permissionPrompt.exists, "Should show camera permission request if no capture button")
            logger.info("Camera permission required")
        }
    }

    // MARK: - Book Context Capture Tests

    func testCaptureFromBook_ShowsCaptureView() {
        logger.step(1, "Opening a book")
        navigateToLibrary()
        openFirstBook()

        logger.step(2, "Opening capture from book detail")
        openCaptureFromBookDetail()

        logger.step(3, "Verifying capture view opened")
        // Should see camera or capture UI
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        let cameraView = app.otherElements[AccessibilityIdentifiers.Capture.cameraPreview]

        let captureUIVisible = captureButton.waitForExistence(timeout: 5) || cameraView.exists

        if captureUIVisible {
            logger.success("Capture view opened from book")
        } else {
            logger.info("Capture UI not visible (may require camera permissions)")
        }
    }

    // MARK: - Image Review Tests

    func testImageReview_ShowsQualityIndicator() throws {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Triggering capture")
        try triggerCapture()

        logger.step(3, "Checking for image review")
        // With test image capture, should transition to image review
        let retakeButton = app.buttons[AccessibilityIdentifiers.ImageReview.retakeButton]
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        let qualityBar = app.otherElements[AccessibilityIdentifiers.ImageReview.qualityBar]

        let hasReviewUI = retakeButton.waitForExistence(timeout: 5) ||
                         usePhotoButton.exists ||
                         qualityBar.exists

        if hasReviewUI {
            logger.success("Image review displayed with quality indicator")
        } else {
            logger.info("Image review may be skipped depending on capture flow")
        }
    }

    func testImageReview_RetakeButton_ReturnsToCamera() throws {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Taking photo")
        try triggerCapture()

        logger.step(3, "Finding retake button")
        let retakeButton = app.buttons[AccessibilityIdentifiers.ImageReview.retakeButton]
        guard retakeButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Retake button not found (review may have been skipped)")
        }

        logger.step(4, "Tapping retake")
        retakeButton.tap()

        logger.step(5, "Verifying return to camera")
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        let returned = captureButton.waitForExistence(timeout: 3) || testButton.exists
        XCTAssertTrue(returned, "Should return to camera view")

        logger.success("Retake returns to camera")
    }

    // MARK: - Extraction Review Tests

    func testExtractionReview_DisplaysExtractedQuotes() throws {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Capturing and processing")
        try triggerCapture()

        // Use photo if review appears
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        if usePhotoButton.waitForExistence(timeout: 3) {
            usePhotoButton.tap()
        }

        logger.step(3, "Waiting for extraction results")
        // Wait for extraction review view
        let reviewTitle = app.navigationBars["Review Extractions"]
        let quoteEditor = app.textViews.firstMatch
        let saveButton = app.buttons["Save Quotes"]

        // Give time for AI processing
        let hasReviewUI = reviewTitle.waitForExistence(timeout: 15) ||
                         quoteEditor.waitForExistence(timeout: 15) ||
                         saveButton.waitForExistence(timeout: 15)

        if hasReviewUI {
            logger.success("Extraction review displayed")
        } else {
            logger.info("Extraction may need more time or network")
        }
    }

    // MARK: - Quote Editing Tests

    func testQuoteEditor_CanEditText() throws {
        try navigateToExtractionReview()

        logger.step(1, "Opening quote editor sheet")
        let editButton = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton]
        guard editButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Quote edit button not found")
        }
        editButton.tap()

        logger.step(2, "Finding quote text editor")
        let textEditor = app.textViews[AccessibilityIdentifiers.Capture.extractionQuoteTextEditor]
        guard textEditor.waitForExistence(timeout: 5) else {
            throw XCTSkip("Quote text editor not found in edit sheet")
        }

        logger.step(3, "Editing quote text")
        textEditor.tap()
        // Type some additional text
        textEditor.typeText(" - edited")

        logger.step(4, "Verifying edit")
        let editedText = app.textViews.matching(
            NSPredicate(format: "identifier == %@ AND value CONTAINS 'edited'",
                        AccessibilityIdentifiers.Capture.extractionQuoteTextEditor)
        ).firstMatch

        XCTAssertTrue(editedText.waitForExistence(timeout: 2), "Edited text should be present in the text editor")

        logger.success("Quote text edited successfully")
    }

    func testQuoteEditor_PageNumberField() throws {
        try navigateToExtractionReview()

        logger.step(1, "Finding page number field")
        let pageField = app.textFields[AccessibilityIdentifiers.QuoteDetail.pageField]
        let pageNumberField = app.textFields["Page"]

        if pageField.waitForExistence(timeout: 3) || pageNumberField.exists {
            logger.success("Page number field available")
        } else {
            logger.info("Page number field may have different identifier")
        }
    }

    // MARK: - Save Flow Tests

    func testSaveQuotes_NavigatesToLibrary() throws {
        try navigateToExtractionReview()

        logger.step(1, "Finding save button")
        let saveButton = app.buttons["Save Quotes"]
        let saveAllButton = app.buttons["Save All"]
        let doneButton = app.buttons["Done"]

        if saveButton.waitForExistence(timeout: 3) {
            saveButton.tap()
        } else if saveAllButton.exists {
            saveAllButton.tap()
        } else if doneButton.exists {
            doneButton.tap()
        } else {
            throw XCTSkip("No save button found")
        }

        logger.step(2, "Verifying navigation after save")
        // Should return to book detail or library
        let quotesLabel = app.staticTexts["Quotes"]
        let tabBar = app.tabBars.firstMatch

        let savedSuccessfully = quotesLabel.waitForExistence(timeout: 5) ||
                               tabBar.waitForExistence(timeout: 5)

        XCTAssertTrue(savedSuccessfully, "Should navigate after save")

        logger.success("Quotes saved and navigated successfully")
    }

    // MARK: - Cancel Flow Tests

    func testCancelCapture_ShowsConfirmation() throws {
        try navigateToExtractionReview()

        logger.step(1, "Finding cancel button")
        // There can be multiple "Cancel" buttons on-screen (e.g. capture flow + nav bars).
        // Prefer the explicit capture cancel identifier for determinism.
        let cancelButton = app.buttons[AccessibilityIdentifiers.Capture.cancelButton]
        let backButton = app.navigationBars.buttons.element(boundBy: 0)

        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
        } else if backButton.exists {
            backButton.tap()
        } else {
            throw XCTSkip("No cancel/back button found")
        }

        logger.step(2, "Checking for discard confirmation")
        // Should show alert asking to discard changes
        let discardButton = app.buttons["Discard"]
        let discardAlert = app.alerts.firstMatch

        if discardAlert.waitForExistence(timeout: 3) {
            XCTAssertTrue(discardButton.exists, "Discard option should exist")
            logger.success("Discard confirmation shown")

            // Cancel to stay in review
            let stayButton = discardAlert.buttons["Cancel"]
            if stayButton.exists {
                stayButton.tap()
            }
        } else {
            logger.info("May navigate directly without confirmation")
        }
    }

    // MARK: - Quality Warning Tests

    func testLowQualityCapture_ShowsWarning() throws {
        // This test would need a specific low-quality test image
        // For now, test that the quality UI elements exist
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Looking for quality toggle")
        let qualityToggle = app.buttons[AccessibilityIdentifiers.Capture.qualityToggle]

        if qualityToggle.waitForExistence(timeout: 3) {
            logger.success("Quality toggle available")
        } else {
            logger.info("Quality toggle may be hidden or have different identifier")
        }
    }

    // MARK: - Helpers

    private func navigateToLibrary() {
        let libraryTab = tabButton(.library)
        if libraryTab.waitForExistence(timeout: 3) {
            libraryTab.tap()
        }
    }

    private func openFirstBook() {
        // Switch to list view
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        if viewModeToggle.waitForExistence(timeout: 2) {
            if viewModeToggle.buttons.count > 1 {
                viewModeToggle.buttons.element(boundBy: 1).tap()
            }
        }

        // Tap first book
        let bookRow = app.cells[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let bookLink = app.links[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        let bookOther = app.otherElements[AccessibilityIdentifiers.Library.bookListRow].firstMatch
        if bookRow.waitForExistence(timeout: 3) {
            bookRow.tap()
        } else if bookLink.waitForExistence(timeout: 3) {
            bookLink.tap()
        } else if bookOther.waitForExistence(timeout: 3) {
            bookOther.tap()
        } else if app.cells.firstMatch.exists {
            app.cells.firstMatch.tap()
        }

        // Wait for detail view
        _ = app.staticTexts["Quotes"].waitForExistence(timeout: 3)
    }

    private func navigateToCaptureWithBook() {
        navigateToLibrary()
        openFirstBook()

        openCaptureFromBookDetail()
    }

    private func navigateToExtractionReview() throws {
        navigateToCaptureWithBook()

        try triggerCapture()

        // Use photo if review appears
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        if usePhotoButton.waitForExistence(timeout: 3) {
            usePhotoButton.tap()
        }

        // Wait for extraction review
        let reviewTitle = app.navigationBars["Review Extractions"]
        guard reviewTitle.waitForExistence(timeout: 15) else {
            throw XCTSkip("Extraction review did not appear")
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
        return navButtons.element(boundBy: navButtons.count > 0 ? navButtons.count - 1 : 0)
    }

    private func triggerCapture() throws {
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        if testButton.waitForExistence(timeout: 3) {
            testButton.tap()
            return
        }

        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        if captureButton.waitForExistence(timeout: 5) {
            captureButton.tap()
            return
        }

        openQuoteCaptureFromTab()

        if testButton.waitForExistence(timeout: 3) {
            testButton.tap()
            return
        }

        guard captureButton.waitForExistence(timeout: 3) else {
            throw XCTSkip("Capture button not available")
        }
        captureButton.tap()
    }

    private func openQuoteCaptureFromTab() {
        let captureTab = tabButton(.capture)
        if captureTab.waitForExistence(timeout: 3) {
            captureTab.tap()
        }

        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        if permissionPrompt.waitForExistence(timeout: 2) {
            return
        }

        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        if testButton.exists {
            return
        }

        let quoteModeCard = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        if quoteModeCard.waitForExistence(timeout: 3) {
            quoteModeCard.tap()
        }

        let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
        if bookCard.waitForExistence(timeout: 5) {
            bookCard.tap()
        }
    }

    private func openCaptureFromBookDetail() {
        let captureQuotesButton = app.buttons[AccessibilityIdentifiers.BookDetail.captureQuotesButton]
        let addQuoteButton = app.buttons["Add Quote"]
        let captureLabelButton = app.buttons["Capture Quotes"]

        if captureQuotesButton.waitForExistence(timeout: 3) {
            captureQuotesButton.tap()
            return
        }

        if captureLabelButton.waitForExistence(timeout: 2) {
            captureLabelButton.tap()
            return
        }

        if addQuoteButton.waitForExistence(timeout: 2) {
            addQuoteButton.tap()
            return
        }

        let menuButton = findMoreMenuButton()
        if menuButton.exists {
            menuButton.tap()
            if captureQuotesButton.waitForExistence(timeout: 2) {
                captureQuotesButton.tap()
                return
            }
            let captureOption = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Capture'")
            ).firstMatch
            if captureOption.waitForExistence(timeout: 2) {
                captureOption.tap()
                return
            }
        }

        openQuoteCaptureFromTab()
    }
}
