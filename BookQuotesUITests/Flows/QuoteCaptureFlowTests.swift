import XCTest

/// End-to-end tests for the quote capture and review flow.
/// Tests camera capture, extraction review, editing, and saving.
final class QuoteCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        var arguments = ["--preload-library-test-data", "--mock-camera", "--mock-extraction-scenario", extractionScenario]
        if name.contains("LowConfidence") {
            arguments.append("--mock-low-confidence")
        }
        return arguments
    }

    private var extractionScenario: String {
        if name.contains("RemoteSource") {
            return "remote"
        }
        if name.contains("LocalFallback") {
            return "local-fallback"
        }
        return "mixed"
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        logger.info("Quote capture tests ready")
    }

    // MARK: - Capture Tab Tests

    func testCaptureTab_DisplaysCameraOrPermission() {
        logger.step(1, "Navigating to Capture tab")
        XCTAssertTrue(tapTab(.capture, timeout: 5), "Capture tab should exist")

        logger.step(2, "Verifying capture view content")
        let modeSelectCover = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        let modeSelectQuote = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        let modeSelectBatch = app.buttons[AccessibilityIdentifiers.Capture.modeSelectBatch]

        XCTAssertTrue(modeSelectCover.waitForExistence(timeout: 5), "Cover capture mode should be available")
        XCTAssertTrue(modeSelectQuote.exists, "Quote capture mode should be available")
        XCTAssertTrue(modeSelectBatch.exists, "Batch capture mode should be available")

        logger.success("Capture tab displays correctly")
    }

    func testCaptureRoot_PassesSystemAccessibilityAudit() throws {
        XCTAssertTrue(tapTab(.capture, timeout: 5), "Capture tab should exist")
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote].waitForExistence(timeout: 5),
            "Capture mode selection should be ready before auditing"
        )
        try performSystemAccessibilityAudit()
    }

    func testCaptureTab_CaptureButton_Exists() {
        logger.step(1, "Navigating to Capture tab")
        openQuoteCaptureFromTab()

        logger.step(2, "Finding capture button")
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5), "Mocked quote capture should provide Use Test Image")
        XCTAssertTrue(testButton.isEnabled, "Test image button should be enabled")
        logger.success("Test image button found and enabled")
    }

    // MARK: - Book Context Capture Tests

    func testCaptureFromBook_ShowsCaptureView() {
        logger.step(1, "Opening a book")
        navigateToLibrary()
        openFirstBook()

        logger.step(2, "Opening capture from book detail")
        openCaptureFromBookDetail()

        logger.step(3, "Verifying capture view opened")
        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Book capture should open mocked quote capture")
        XCTAssertTrue(testImageButton.isEnabled, "Book capture test image control should be enabled")
        logger.success("Capture view opened from book")
    }

    // MARK: - Image Review Tests

    func testImageReview_ShowsQualityIndicator() {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Triggering capture")
        triggerCapture()

        logger.step(3, "Checking for image review")
        // With test image capture, should transition to image review
        let retakeButton = app.buttons[AccessibilityIdentifiers.ImageReview.retakeButton]
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        let qualityBar = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.ImageReview.qualityBar)
            .firstMatch

        XCTAssertTrue(retakeButton.waitForExistence(timeout: 5), "Image review should provide Retake")
        XCTAssertTrue(usePhotoButton.exists, "Image review should provide Use Photo")
        XCTAssertTrue(qualityBar.exists, "Image review should expose quality feedback")
        logger.success("Image review displayed with quality indicator")
    }

    func testImageReview_RetakeButton_ReturnsToCamera() {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Taking photo")
        triggerCapture()

        logger.step(3, "Finding retake button")
        let retakeButton = app.buttons[AccessibilityIdentifiers.ImageReview.retakeButton]
        XCTAssertTrue(retakeButton.waitForExistence(timeout: 5), "Image review should provide Retake")

        logger.step(4, "Tapping retake")
        retakeButton.tap()

        logger.step(5, "Verifying return to camera")
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        let returned = captureButton.waitForExistence(timeout: 3) || testButton.exists
        XCTAssertTrue(returned, "Should return to camera view")

        logger.success("Retake returns to camera")
    }

    func testImageReview_PassesSystemAccessibilityAudit() throws {
        navigateToCaptureWithBook()
        triggerCapture()

        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton].waitForExistence(timeout: 5),
            "Image review should be ready before auditing"
        )
        try performSystemAccessibilityAudit()
    }

    // MARK: - Extraction Review Tests

    func testExtractionReview_DisplaysExtractedQuotes() {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Capturing and processing")
        triggerCapture()

        // Use photo if review appears
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        if usePhotoButton.waitForExistence(timeout: 3) {
            usePhotoButton.tap()
        }

        logger.step(3, "Waiting for extraction results")
        // Wait for extraction review view with actual extracted quote controls.
        let reviewTitle = app.navigationBars["Review Extractions"]
        let editButton = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton]
        let saveButton = app.buttons["Save All"]
        let modelSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_model_assisted")
            .firstMatch
        let onDeviceSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_on_device")
            .firstMatch
        let failureTitle = app.staticTexts["Extraction Failed"]
        let noQuotesTitle = app.staticTexts["No Quotes Found"]
        let remoteConsentButton = app.buttons["Allow Remote AI Processing"]

        XCTAssertTrue(reviewTitle.waitForExistence(timeout: 15), "Extraction review should appear")
        XCTAssertFalse(
            remoteConsentButton.exists,
            "On-device quote review must not be blocked by the optional remote-AI consent sheet"
        )
        XCTAssertFalse(failureTitle.exists, "Extraction should not fail in mock-camera UI smoke")
        XCTAssertFalse(noQuotesTitle.exists, "Mock-camera extraction should return at least one quote")

        let hasExtractedQuoteControls = editButton.waitForExistence(timeout: 10) || saveButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasExtractedQuoteControls, "Extraction review should show editable extracted quote controls")
        XCTAssertTrue(saveButton.exists && saveButton.isEnabled, "Save All should be enabled when mock extraction returns quotes")
        XCTAssertTrue(modelSource.exists, "Review should identify the model-assisted candidate")
        XCTAssertTrue(onDeviceSource.exists, "Review should identify the on-device candidate")

        logger.success("Extraction review displayed extracted quotes")
    }

    func testExtractionReview_ShowsRemoteSource() {
        navigateToExtractionReview()

        let modelSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_model_assisted")
            .firstMatch

        XCTAssertTrue(modelSource.waitForExistence(timeout: 5))
    }

    func testExtractionReview_ShowsLocalFallback() {
        navigateToExtractionReview()

        let onDeviceSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_on_device")
            .firstMatch
        let fallbackNotice = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionFallbackNotice)
            .firstMatch

        XCTAssertTrue(onDeviceSource.waitForExistence(timeout: 5))
        XCTAssertTrue(fallbackNotice.waitForExistence(timeout: 5))
    }

    // MARK: - Quote Editing Tests

    func testQuoteEditor_CanEditText() {
        navigateToExtractionReview()

        logger.step(1, "Opening quote editor sheet")
        let editButton = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton].firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Extraction review should provide quote editing")
        editButton.tap()

        logger.step(2, "Finding quote text editor")
        let textEditor = app.textViews[AccessibilityIdentifiers.Capture.extractionQuoteTextEditor]
        XCTAssertTrue(textEditor.waitForExistence(timeout: 5), "Quote editor sheet should expose editable text")

        logger.step(3, "Editing quote text")
        XCTAssertTrue(
            app.keyboards.firstMatch.waitForExistence(timeout: 5),
            "Quote editor should receive keyboard focus"
        )
        textEditor.tap()
        textEditor.typeText(" - edited")

        logger.step(4, "Verifying edit")
        let editedText = app.textViews.matching(
            NSPredicate(format: "identifier == %@ AND value CONTAINS 'edited'",
                        AccessibilityIdentifiers.Capture.extractionQuoteTextEditor)
        ).firstMatch
        XCTAssertTrue(editedText.waitForExistence(timeout: 2), "Edited text should be present in the text editor")

        logger.success("Quote text edited successfully")
    }

    func testExtractionReview_DisplaysDetectedPageNumber() {
        navigateToExtractionReview()

        logger.step(1, "Finding detected page number")
        XCTAssertTrue(
            app.staticTexts["p. 38"].waitForExistence(timeout: 5),
            "Mock extraction should display the candidate's detected page number"
        )
        logger.success("Detected page number is displayed")
    }

    // MARK: - Save Flow Tests

    func testSaveQuotes_NavigatesToBookDetail() {
        navigateToExtractionReview()

        logger.step(1, "Finding save button")
        let saveAllButton = app.buttons["Save All"]
        XCTAssertTrue(saveAllButton.waitForExistence(timeout: 5), "Extraction review should provide Save All")
        XCTAssertTrue(saveAllButton.isEnabled, "Save All should be enabled for extracted quotes")
        saveAllButton.tap()

        logger.step(2, "Verifying navigation after save")
        let bookDetailTitle = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        XCTAssertTrue(bookDetailTitle.waitForExistence(timeout: 8), "Saving quotes should return to the captured book")

        logger.success("Quotes saved and navigated successfully")
    }

    // MARK: - Cancel Flow Tests

    func testCancelCapture_ShowsConfirmation() {
        navigateToExtractionReview()

        logger.step(1, "Finding cancel button")
        let cancelButton = app.buttons[AccessibilityIdentifiers.Capture.cancelButton]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Extraction review should provide Cancel")
        cancelButton.tap()

        logger.step(2, "Checking for discard confirmation")
        // Should show alert asking to discard changes
        let discardButton = app.buttons["Discard"]
        let discardAlert = app.alerts.firstMatch

        XCTAssertTrue(discardAlert.waitForExistence(timeout: 3), "Cancel with unsaved quotes should request confirmation")
        XCTAssertTrue(discardButton.exists, "Discard option should exist")
        logger.success("Discard confirmation shown")

        let keepEditingButton = discardAlert.buttons["Keep Editing"]
        XCTAssertTrue(keepEditingButton.exists, "Keep Editing should preserve the review")
        keepEditingButton.tap()
    }

    // MARK: - Quality Warning Tests

    func testLowConfidenceExtraction_ShowsReducedConfidence() {
        logger.step(1, "Opening low-confidence extraction review")
        navigateToExtractionReview()

        logger.step(2, "Verifying reduced confidence")
        XCTAssertTrue(
            app.staticTexts["48%"].waitForExistence(timeout: 5),
            "Low-confidence mock extraction should display its reduced confidence"
        )
        logger.success("Low-confidence extraction is visible to the reader")
    }

    // MARK: - Helpers

    private func navigateToLibrary() {
        XCTAssertTrue(tapTab(.library), "Library tab should be available")
    }

    private func openFirstBook() {
        // Switch to list view
        let viewModeToggle = app.segmentedControls[AccessibilityIdentifiers.Library.viewModeToggle]
        if viewModeToggle.waitForExistence(timeout: 2) {
            if viewModeToggle.buttons.count > 1 {
                viewModeToggle.buttons.element(boundBy: 1).tap()
            }
        }

        let bookCandidates = [
            app.buttons[AccessibilityIdentifiers.Library.bookListRow].firstMatch,
            app.buttons[AccessibilityIdentifiers.Library.bookCoverCard].firstMatch,
            app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Library.bookListRow)
                .firstMatch,
            app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Library.bookCoverCard)
                .firstMatch
        ]
        guard let book = bookCandidates.first(where: { revealForInteraction($0) }) else {
            XCTFail("Seeded library should expose a reachable book")
            return
        }
        book.tap()

        XCTAssertTrue(
            app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].waitForExistence(timeout: 5),
            "Opening a seeded book should show its detail screen"
        )
    }

    private func navigateToCaptureWithBook() {
        openQuoteCaptureFromTabSelectingBook()
    }

    private func navigateToExtractionReview() {
        navigateToCaptureWithBook()

        triggerCapture()

        // Use photo if review appears
        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        if usePhotoButton.waitForExistence(timeout: 3) {
            usePhotoButton.tap()
        }

        // Wait for extraction review
        let reviewTitle = app.navigationBars["Review Extractions"]
        XCTAssertTrue(reviewTitle.waitForExistence(timeout: 15), "Mock capture should open extraction review")
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

    private func triggerCapture() {
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5), "Mocked quote capture should provide Use Test Image")
        testButton.tap()
    }

    private func openQuoteCaptureFromTab() {
        openQuoteCaptureFromTabSelectingBook()
    }

    private func openQuoteCaptureFromTabSelectingBook() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        XCTAssertFalse(permissionPrompt.waitForExistence(timeout: 2), "Mock camera should not request permission")

        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        if testButton.exists {
            return
        }

        let quoteModeCard = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
        if quoteModeCard.waitForExistence(timeout: 3) {
            quoteModeCard.tap()
        }

        let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5), "Seeded library should provide a book for quote capture")
        bookCard.tap()

        XCTAssertTrue(testButton.waitForExistence(timeout: 5), "Quote capture should show Use Test Image")
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

        XCTFail("Book detail should provide a Capture Quotes action")
    }
}

/// Regression coverage for extraction review on compact layouts with accessibility text.
final class AdaptiveExtractionReviewLayoutTests: BaseUITestCase {

    override func setUp() {
        XCUIDevice.shared.orientation = .portrait
        super.setUp()
        XCTAssertTrue(
            waitUntil("portrait orientation", timeout: 5) { [weak self] in
                guard let self else { return false }
                return self.app.frame.height > self.app.frame.width
            },
            "Each adaptive-layout test should begin in portrait orientation"
        )
    }

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "--mock-extraction-scenario", "mixed",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    func testExtractionReviewStacksControlsWithAccessibilityText() {
        openExtractionReview()

        let pageSelector = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageSelector)
            .firstMatch
        let sourceImage = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageImage)
            .firstMatch

        XCTAssertTrue(pageSelector.waitForExistence(timeout: 5), "Extraction review should expose its page selector")
        XCTAssertGreaterThan(
            pageSelector.frame.width,
            app.frame.width * 0.7,
            "Compact accessibility layouts should place the page selector above the editor"
        )
        XCTAssertTrue(sourceImage.waitForExistence(timeout: 5), "Extraction review should expose the source image")
        XCTAssertTrue(sourceImage.isHittable, "The source image should be reachable by assistive technologies")
        captureScreenshot(named: "accessibility_text_stacked_review", description: "Compact extraction review at accessibility text size")
        openVisibleQuoteEditor()
    }

    func testSourceImageAccessibleActionOpensFullScreen() throws {
        openExtractionReview()

        let sourceImage = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageImage)
            .firstMatch
        XCTAssertTrue(sourceImage.waitForExistence(timeout: 5), "Extraction review should expose its source image")
        XCTAssertTrue(sourceImage.isHittable, "The source image should be available as an accessibility action")
        sourceImage.tap()

        let closeButton = app.buttons["Close image"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5), "Activating the source image should open its full-screen viewer")
        XCTAssertTrue(app.staticTexts["Page 38"].exists, "The full-screen viewer should retain the detected page context")
        try performSystemAccessibilityAudit()
        closeButton.tap()

        XCTAssertTrue(
            app.navigationBars["Review Extractions"].waitForExistence(timeout: 5),
            "Closing the source image should return to extraction review"
        )
    }

    func testExtractionReviewRemainsUsableInLandscapeWithAccessibilityText() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        XCTAssertTrue(
            waitUntil("landscape orientation", timeout: 5) { [weak self] in
                guard let self else { return false }
                return self.app.frame.width > self.app.frame.height
            },
            "The simulator should rotate before beginning the extraction review"
        )

        openExtractionReview()

        let pageSelector = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageSelector)
            .firstMatch
        let sourceImage = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageImage)
            .firstMatch

        XCTAssertTrue(pageSelector.waitForExistence(timeout: 5), "Landscape review should expose its page selector")
        XCTAssertGreaterThan(
            pageSelector.frame.width,
            app.frame.width * 0.7,
            "Accessibility text should keep the page selector above the editor in landscape"
        )
        XCTAssertTrue(sourceImage.waitForExistence(timeout: 5), "Landscape review should expose the source image")
        XCTAssertTrue(sourceImage.isHittable, "The source image should remain reachable in landscape")
        captureScreenshot(named: "accessibility_text_landscape_review", description: "Landscape extraction review at accessibility text size")
        openVisibleQuoteEditor()
    }

    private func openExtractionReview() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        if !testImageButton.waitForExistence(timeout: 2) {
            let quoteModeCard = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
            XCTAssertTrue(quoteModeCard.waitForExistence(timeout: 3), "Quote capture mode should be available")
            quoteModeCard.tap()

            let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
            XCTAssertTrue(bookCard.waitForExistence(timeout: 5), "Seeded library should provide a book for quote capture")
            bookCard.tap()
        }

        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Quote capture should show Use Test Image")
        testImageButton.tap()

        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        if usePhotoButton.waitForExistence(timeout: 3) {
            usePhotoButton.tap()
        }

        XCTAssertTrue(
            app.navigationBars["Review Extractions"].waitForExistence(timeout: 15),
            "Mock capture should open extraction review"
        )
    }

    private func openVisibleQuoteEditor() {
        let reviewScrollView = app.scrollViews[AccessibilityIdentifiers.Capture.extractionReviewScrollView]
        XCTAssertTrue(reviewScrollView.waitForExistence(timeout: 5), "Compact review should expose its vertical scroll surface")

        for _ in 0..<3 {
            if let editButton = visibleQuoteEditButton() {
                editButton.tap()
                XCTAssertTrue(
                    app.navigationBars["Edit Quote"].waitForExistence(timeout: 5),
                    "Extracted quotes should remain editable"
                )
                return
            }
            reviewScrollView.swipeUp()
        }

        XCTFail("A visible edit control should be available after scrolling the extraction review")
    }

    private func visibleQuoteEditButton() -> XCUIElement? {
        let editButtons = app.buttons.matching(identifier: AccessibilityIdentifiers.Capture.extractionQuoteEditButton)
        for index in 0..<editButtons.count {
            let editButton = editButtons.element(boundBy: index)
            let frame = editButton.frame
            if frame.height > 0,
               frame.minY >= app.navigationBars["Review Extractions"].frame.maxY,
               frame.maxY <= app.frame.maxY {
                return editButton
            }
        }
        return nil
    }
}

/// Regression coverage for the regular-width iPad extraction review layout.
final class IPadExtractionReviewLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "--mock-extraction-scenario", "mixed"
        ]
    }

    func testExtractionReviewUsesLayoutForCurrentWidth() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        if !testImageButton.waitForExistence(timeout: 2) {
            let quoteModeCard = app.buttons[AccessibilityIdentifiers.Capture.modeSelectQuote]
            XCTAssertTrue(quoteModeCard.waitForExistence(timeout: 3), "Quote capture mode should be available")
            quoteModeCard.tap()

            let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
            XCTAssertTrue(bookCard.waitForExistence(timeout: 5), "Seeded library should provide a book for quote capture")
            bookCard.tap()
        }

        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Quote capture should show Use Test Image")
        testImageButton.tap()

        let usePhotoButton = app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton]
        if usePhotoButton.waitForExistence(timeout: 3) {
            usePhotoButton.tap()
        }

        XCTAssertTrue(
            app.navigationBars["Review Extractions"].waitForExistence(timeout: 15),
            "Mock capture should open extraction review"
        )

        let pageSelector = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageSelector)
            .firstMatch
        let sourceImage = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageImage)
            .firstMatch

        XCTAssertTrue(pageSelector.waitForExistence(timeout: 5), "Extraction review should expose its page selector")
        if app.frame.width >= 700 {
            XCTAssertLessThan(
                pageSelector.frame.width,
                app.frame.width * 0.25,
                "Regular-width layouts should keep the page selector beside the editor"
            )
        } else {
            XCTAssertGreaterThan(
                pageSelector.frame.width,
                app.frame.width * 0.5,
                "Compact-width layouts should keep the page selector above the editor"
            )
        }
        XCTAssertTrue(sourceImage.waitForExistence(timeout: 5), "Extraction review should expose the source image")
        captureScreenshot(named: "ipad_side_by_side_review", description: "iPad extraction review at normal text size")
    }
}
