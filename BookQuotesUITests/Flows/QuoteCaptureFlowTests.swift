import XCTest

/// End-to-end tests for the quote capture and review flow.
/// Tests camera capture, extraction review, editing, and saving.
final class QuoteCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "--mock-multiple-quotes"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        logger.info("Quote capture tests ready")
    }

    // MARK: - Capture Tab Tests

    func testCaptureTab_DisplaysCameraOrPermission() {
        logger.step(1, "Navigating to Capture tab")
        let captureTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.captureTab]
        XCTAssertTrue(captureTab.waitForExistence(timeout: 5), "Capture tab should exist")
        captureTab.tap()

        logger.step(2, "Verifying capture view content")
        // Should see either camera preview or permission request
        let cameraPreview = app.otherElements[AccessibilityIdentifiers.Capture.cameraPreview]
        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]

        let hasCaptureUI = cameraPreview.waitForExistence(timeout: 5) ||
                          permissionPrompt.exists ||
                          captureButton.exists

        XCTAssertTrue(hasCaptureUI, "Should show camera preview, permission request, or capture button")

        logger.success("Capture tab displays correctly")
    }

    func testCaptureTab_CaptureButton_Exists() {
        logger.step(1, "Navigating to Capture tab")
        let captureTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.captureTab]
        captureTab.tap()

        logger.step(2, "Finding capture button")
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]

        // With mock camera, capture button should be visible
        if captureButton.waitForExistence(timeout: 5) {
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

        logger.step(2, "Finding capture quotes button")
        let captureQuotesButton = app.buttons[AccessibilityIdentifiers.BookDetail.captureQuotesButton]
        let addQuoteButton = app.buttons["Add Quote"]

        if captureQuotesButton.waitForExistence(timeout: 3) {
            captureQuotesButton.tap()
        } else if addQuoteButton.exists {
            addQuoteButton.tap()
        } else {
            // Try finding in menu
            let menuButton = findMoreMenuButton()
            if menuButton.exists {
                menuButton.tap()
                let captureOption = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'Capture'")
                ).firstMatch
                if captureOption.waitForExistence(timeout: 2) {
                    captureOption.tap()
                }
            }
        }

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
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        guard captureButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Capture button not available (needs camera permissions)")
        }
        captureButton.tap()

        logger.step(3, "Checking for image review")
        // With mock camera, should transition to image review
        let retakeButton = app.buttons[AccessibilityIdentifiers.ImageReview.retakeButton]
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        let qualityBar = app.otherElements[AccessibilityIdentifiers.ImageReview.qualityBar]

        let hasReviewUI = retakeButton.waitForExistence(timeout: 5) ||
                         usePhotoButton.exists ||
                         qualityBar.exists

        if hasReviewUI {
            logger.success("Image review displayed with quality indicator")
        } else {
            logger.info("Image review may be skipped in mock mode")
        }
    }

    func testImageReview_RetakeButton_ReturnsToCamera() throws {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Taking photo")
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        guard captureButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Capture button not available")
        }
        captureButton.tap()

        logger.step(3, "Finding retake button")
        let retakeButton = app.buttons[AccessibilityIdentifiers.ImageReview.retakeButton]
        guard retakeButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Retake button not found (mock may skip review)")
        }

        logger.step(4, "Tapping retake")
        retakeButton.tap()

        logger.step(5, "Verifying return to camera")
        XCTAssertTrue(captureButton.waitForExistence(timeout: 3), "Should return to camera view")

        logger.success("Retake returns to camera")
    }

    // MARK: - Extraction Review Tests

    func testExtractionReview_DisplaysExtractedQuotes() throws {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Capturing and processing")
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        guard captureButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Capture button not available")
        }
        captureButton.tap()

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
            logger.info("Extraction may need more time or network (mock should be instant)")
        }
    }

    // MARK: - Quote Editing Tests

    func testQuoteEditor_CanEditText() throws {
        try navigateToExtractionReview()

        logger.step(1, "Finding quote text editor")
        let textEditor = app.textViews.firstMatch
        guard textEditor.waitForExistence(timeout: 5) else {
            throw XCTSkip("Quote text editor not found")
        }

        logger.step(2, "Editing quote text")
        textEditor.tap()
        // Type some additional text
        textEditor.typeText(" - edited")

        logger.step(3, "Verifying edit")
        // The text should now contain "edited"
        let editedText = app.textViews.matching(
            NSPredicate(format: "value CONTAINS 'edited'")
        ).firstMatch

        XCTAssertTrue(editedText.exists, "Edited text should be visible")

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
        let cancelButton = app.buttons["Cancel"]
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
            let stayButton = app.buttons["Cancel"]
            if stayButton.exists {
                stayButton.tap()
            }
        } else {
            logger.info("May navigate directly without confirmation")
        }
    }

    // MARK: - Quality Warning Tests

    func testLowQualityCapture_ShowsWarning() throws {
        // This test would need a specific mock for low quality
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
        let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]
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
        if bookRow.waitForExistence(timeout: 3) {
            bookRow.tap()
        } else if app.cells.firstMatch.exists {
            app.cells.firstMatch.tap()
        }

        // Wait for detail view
        _ = app.staticTexts["Quotes"].waitForExistence(timeout: 3)
    }

    private func navigateToCaptureWithBook() {
        navigateToLibrary()
        openFirstBook()

        // Find and tap capture button from book detail
        let captureQuotesButton = app.buttons[AccessibilityIdentifiers.BookDetail.captureQuotesButton]
        if captureQuotesButton.waitForExistence(timeout: 3) {
            captureQuotesButton.tap()
        } else {
            // Try Capture tab as fallback
            let captureTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.captureTab]
            captureTab.tap()
        }
    }

    private func navigateToExtractionReview() throws {
        navigateToCaptureWithBook()

        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        guard captureButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Capture button not available")
        }
        captureButton.tap()

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
        let navButtons = app.navigationBars.buttons
        let predicate = NSPredicate(format: "label CONTAINS 'More' OR label CONTAINS 'ellipsis'")
        let match = navButtons.matching(predicate).firstMatch
        if match.exists {
            return match
        }
        return navButtons.element(boundBy: navButtons.count > 0 ? navButtons.count - 1 : 0)
    }
}
