import XCTest

/// End-to-end tests for the batch/multi-page capture workflow.
final class BatchCaptureFlowTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "--mock-extraction-scenario", "remote"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        logger.info("Batch capture tests ready")
    }

    // MARK: - Batch Capture Entry Tests

    func testBatchCapture_OpensFromCaptureTab() {
        openBatchCapture()

        let pageCounter = app.staticTexts[AccessibilityIdentifiers.Capture.pageCounter]
        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]

        XCTAssertTrue(pageCounter.exists, "Batch capture should display a page counter")
        XCTAssertTrue(testImageButton.exists && testImageButton.isEnabled, "Mock batch capture should provide Use Test Image")
    }

    // MARK: - Page Counter Tests

    func testBatchCapture_PageCounter_StartsAtZero() {
        openBatchCapture()
        assertPageCount(0)
    }

    func testBatchCapture_CapturePhoto_IncrementsCounter() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)
    }

    // MARK: - Photo Strip Tests

    func testBatchCapture_AfterCapture_ShowsPhotoStrip() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)

        let strip = app.buttons[AccessibilityIdentifiers.Capture.photoStrip]
        XCTAssertTrue(strip.waitForExistence(timeout: 8), "Capturing a page should fill the photo strip")
        XCTAssertTrue(strip.isHittable, "Photo strip should be available for review")
    }

    func testBatchCapture_PhotoStrip_CanRemoveCapture() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)

        let strip = app.buttons[AccessibilityIdentifiers.Capture.photoStrip]
        XCTAssertTrue(strip.waitForExistence(timeout: 8), "A captured page should appear in the photo strip")
        strip.tap()

        let removeButton = app.buttons[AccessibilityIdentifiers.Capture.removePageButton]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5), "Capture detail should provide Remove Page")
        removeButton.tap()

        assertPageCount(0)
        XCTAssertFalse(strip.waitForExistence(timeout: 2), "Removing the only page should clear the photo strip")
    }

    func testBatchCapture_MultipleCaptures_UpdatesCountBadge() {
        openBatchCapture()

        for expectedPageCount in 1...3 {
            captureTestPage(expectedPageCount: expectedPageCount)
        }

        let strip = app.buttons[AccessibilityIdentifiers.Capture.photoStrip]
        XCTAssertTrue(strip.waitForExistence(timeout: 8), "The photo strip should remain after multiple captures")
        XCTAssertTrue(
            strip.label.contains("3"),
            "Photo strip accessibility label should include the page count"
        )
    }

    // MARK: - Done Button Tests

    func testBatchCapture_DoneButton_DisabledWithNoCaptures() {
        openBatchCapture()

        let doneButton = app.buttons[AccessibilityIdentifiers.Capture.doneButton]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Batch capture should provide Done")
        XCTAssertFalse(doneButton.isEnabled, "Done must be disabled before any pages are captured")
    }

    func testBatchCapture_DoneButton_EnabledAfterCapture() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)

        let doneButton = app.buttons[AccessibilityIdentifiers.Capture.doneButton]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Batch capture should provide Done")
        XCTAssertTrue(doneButton.isEnabled, "Done should be enabled after a capture")
    }

    // MARK: - Session Completion Tests

    func testBatchCapture_DoneOpensPassagesSheet() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)
        finishCaptureSession()

        let consentButton = app.buttons["Allow Remote AI Processing"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        XCTAssertTrue(
            app.navigationBars["Passages"].waitForExistence(timeout: 15)
                || app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].waitForExistence(timeout: 2),
            "Done should open the Passages sheet"
        )

        let modelSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_model_assisted")
            .firstMatch
        XCTAssertTrue(modelSource.waitForExistence(timeout: 15), "Mock batch processing should render extracted model-assisted content")
    }

    func testBatchCapture_PassagesShowsPageHeadersAndViewPage() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)
        captureTestPage(expectedPageCount: 2)
        finishCaptureSession()

        let consentButton = app.buttons["Allow Remote AI Processing"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        XCTAssertTrue(
            app.navigationBars["Passages"].waitForExistence(timeout: 15)
                || app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].waitForExistence(timeout: 2),
            "Done should open the Passages sheet"
        )

        let viewPage = app.buttons[AccessibilityIdentifiers.Capture.viewPageButton].firstMatch
        XCTAssertTrue(viewPage.waitForExistence(timeout: 10), "Multi-page Passages should provide View page")
        viewPage.tap()

        let closeImage = app.buttons["Close image"]
        XCTAssertTrue(closeImage.waitForExistence(timeout: 5), "View page should open the full-page viewer")
        closeImage.tap()

        XCTAssertTrue(
            app.navigationBars["Passages"].waitForExistence(timeout: 5)
                || app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].waitForExistence(timeout: 2),
            "Closing the page viewer should return to Passages"
        )
    }

    func testBatchCapture_SaveDraftOption_SavesWithoutProcessing() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)

        let cancelButton = app.buttons[AccessibilityIdentifiers.Capture.cancelButton]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Batch capture should provide Cancel")
        cancelButton.tap()

        let saveDraftButton = app.buttons[AccessibilityIdentifiers.Capture.saveDraftButton].firstMatch
        XCTAssertTrue(saveDraftButton.waitForExistence(timeout: 5), "Cancelling a non-empty batch should provide Save Draft")
        saveDraftButton.tap()

        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.modeMenu].waitForExistence(timeout: 5),
            "Saving a draft should return to single-page capture"
        )

        chooseCaptureModeMenuItem(
            identifier: AccessibilityIdentifiers.Capture.savedDraftsButton,
            label: "Saved Drafts (1)"
        )

        XCTAssertTrue(app.staticTexts["Saved Drafts"].waitForExistence(timeout: 5), "Saved drafts should open from the capture menu")

        let resumeDraft = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'capture_resume_draft_'")
        ).firstMatch
        XCTAssertTrue(resumeDraft.waitForExistence(timeout: 5), "Saved draft should be resumable")
        resumeDraft.tap()

        assertPageCount(1)
    }

    // MARK: - Cancel Flow Tests

    func testBatchCapture_CancelWithNoCaptures_DismissesImmediately() {
        openBatchCapture()

        let cancelButton = app.buttons[AccessibilityIdentifiers.Capture.cancelButton]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Batch capture should provide Cancel")
        cancelButton.tap()

        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.modeMenu].waitForExistence(timeout: 5)
                || app.buttons[AccessibilityIdentifiers.Capture.testImageButton].waitForExistence(timeout: 2),
            "Cancelling an empty batch should return to single-page capture"
        )
    }

    func testBatchCapture_CancelWithCaptures_ShowsConfirmation() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)

        let cancelButton = app.buttons[AccessibilityIdentifiers.Capture.cancelButton]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Batch capture should provide Cancel")
        cancelButton.tap()

        let processButton = app.buttons[AccessibilityIdentifiers.Capture.processBatchButton].firstMatch
        let saveDraftButton = app.buttons[AccessibilityIdentifiers.Capture.saveDraftButton].firstMatch
        XCTAssertTrue(processButton.waitForExistence(timeout: 5), "Cancelling a non-empty batch should request a decision")
        XCTAssertTrue(saveDraftButton.exists, "Cancellation decision should allow saving a draft")
    }

    // MARK: - Helpers

    private var pageCounter: XCUIElement {
        app.staticTexts[AccessibilityIdentifiers.Capture.pageCounter]
    }

    private func openBatchCapture() {
        openBatchCaptureFromTab()
        assertPageCount(0)
    }

    private func captureTestPage(expectedPageCount: Int) {
        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Batch capture should provide Use Test Image")
        XCTAssertTrue(testImageButton.isEnabled, "Use Test Image should be enabled before capture")
        testImageButton.tap()
        assertPageCount(expectedPageCount)
    }

    private func finishCaptureSession() {
        let doneButton = app.buttons[AccessibilityIdentifiers.Capture.doneButton]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Batch capture should provide Done")
        XCTAssertTrue(doneButton.isEnabled, "Done should be enabled after at least one capture")
        doneButton.tap()
    }

    private func assertPageCount(_ expected: Int) {
        let expectedLabel = "\(expected) page\(expected == 1 ? "" : "s") in session"
        XCTAssertTrue(
            waitUntil("page counter shows \(expected)", timeout: 8) {
                self.pageCounter.exists && self.pageCounter.label == expectedLabel
            },
            "Page counter should read \(expectedLabel)"
        )
    }
}

/// Regression coverage for multi-page capture at the largest supported text size.
final class AdaptiveBatchCaptureLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    func testBatchCaptureControlsRemainReachableWithAccessibilityText() {
        openBatchCaptureFromTab()

        let testImage = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        let done = app.buttons[AccessibilityIdentifiers.Capture.doneButton]
        XCTAssertTrue(testImage.waitForExistence(timeout: 5), "Batch capture should provide Use Test Image")
        XCTAssertTrue(testImage.isHittable, "Batch capture action should remain reachable")
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Batch capture should provide Done")
        XCTAssertTrue(done.isHittable, "Batch Done action should remain reachable")

        testImage.tap()

        let strip = app.buttons[AccessibilityIdentifiers.Capture.photoStrip]
        XCTAssertTrue(strip.waitForExistence(timeout: 8), "Captured batch page should fill the photo strip")
        XCTAssertTrue(strip.isHittable, "Photo strip should remain reachable")
        captureScreenshot(named: "accessibility_text_batch_capture", description: "Batch capture at accessibility text size")
    }
}
