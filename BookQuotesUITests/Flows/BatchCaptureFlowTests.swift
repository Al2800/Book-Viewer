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

    // MARK: - Thumbnail Strip Tests

    func testBatchCapture_AfterCapture_ShowsThumbnail() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)

        XCTAssertTrue(waitForThumbnailCount(1), "Capturing a page should add a thumbnail")
        XCTAssertTrue(thumbnailElements.firstMatch.isHittable, "Captured thumbnail should be available for review")
    }

    func testBatchCapture_ThumbnailDetail_CanRemoveCapture() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)
        XCTAssertTrue(waitForThumbnailCount(1), "A captured page should have a thumbnail")

        let thumbnail = thumbnailElements.firstMatch
        thumbnail.tap()

        let removeButton = app.buttons[AccessibilityIdentifiers.Capture.removePageButton]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5), "Capture detail should provide Remove Page")
        removeButton.tap()

        assertPageCount(0)
        XCTAssertTrue(waitForThumbnailCount(0), "Removing the only page should remove its thumbnail")
    }

    func testBatchCapture_MultipleCaptures_ShowsMultipleThumbnails() {
        openBatchCapture()

        for expectedPageCount in 1...3 {
            captureTestPage(expectedPageCount: expectedPageCount)
        }

        XCTAssertTrue(waitForThumbnailCount(3), "Each captured page should have its own thumbnail")
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

        finishCaptureSession()

        let processButton = app.buttons[AccessibilityIdentifiers.Capture.processBatchButton].firstMatch
        let saveDraftButton = app.buttons[AccessibilityIdentifiers.Capture.saveDraftButton].firstMatch
        XCTAssertTrue(processButton.waitForExistence(timeout: 5), "Done should offer processing after a capture")
        XCTAssertTrue(saveDraftButton.exists, "Done should offer saving a draft after a capture")
    }

    // MARK: - Session Completion Tests

    func testBatchCapture_ProcessOption_ProcessesCaptures() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)
        finishCaptureSession()

        let processButton = app.buttons[AccessibilityIdentifiers.Capture.processBatchButton].firstMatch
        XCTAssertTrue(processButton.waitForExistence(timeout: 5), "Batch completion should provide Process")
        processButton.tap()

        let consentButton = app.buttons["Allow Remote AI Processing"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        let reviewTitle = app.navigationBars["Review Extractions"]
        XCTAssertTrue(reviewTitle.waitForExistence(timeout: 15), "Processing a batch should open extraction review")

        let modelSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_model_assisted")
            .firstMatch
        XCTAssertTrue(modelSource.waitForExistence(timeout: 15), "Mock batch processing should render extracted model-assisted content")
    }

    func testBatchCapture_SaveDraftOption_SavesWithoutProcessing() {
        openBatchCapture()
        captureTestPage(expectedPageCount: 1)
        finishCaptureSession()

        let saveDraftButton = app.buttons[AccessibilityIdentifiers.Capture.saveDraftButton].firstMatch
        XCTAssertTrue(saveDraftButton.waitForExistence(timeout: 5), "Batch completion should provide Save Draft")
        saveDraftButton.tap()

        XCTAssertTrue(app.staticTexts["Saved Drafts"].waitForExistence(timeout: 5), "Saved drafts should be visible on Capture")

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
            app.buttons[AccessibilityIdentifiers.Capture.modeSelectBatch].waitForExistence(timeout: 5),
            "Cancelling an empty batch should return to capture mode selection"
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

    private var thumbnailElements: XCUIElementQuery {
        app.buttons.matching(identifier: AccessibilityIdentifiers.Capture.thumbnail)
    }

    private func openBatchCapture() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        XCTAssertFalse(permissionPrompt.waitForExistence(timeout: 2), "Mock camera should not request permission")

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        if testImageButton.exists && pageCounter.exists {
            return
        }

        let batchModeCard = app.buttons[AccessibilityIdentifiers.Capture.modeSelectBatch]
        XCTAssertTrue(batchModeCard.waitForExistence(timeout: 5), "Capture should offer batch mode")
        batchModeCard.tap()

        let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5), "Seeded library should provide a book for batch capture")
        bookCard.tap()

        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Batch capture should provide Use Test Image")
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

    private func waitForThumbnailCount(_ expected: Int) -> Bool {
        waitUntil("thumbnail count is \(expected)", timeout: 8) {
            self.thumbnailElements.count == expected
        }
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
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let batchMode = app.buttons[AccessibilityIdentifiers.Capture.modeSelectBatch]
        XCTAssertTrue(batchMode.waitForExistence(timeout: 5), "Capture should offer batch mode")
        XCTAssertTrue(reveal(batchMode), "Batch mode should remain reachable after scrolling")
        batchMode.tap()

        let book = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 5), "Seeded library should provide a book")
        XCTAssertTrue(book.isHittable, "Batch book selection should remain reachable")
        book.tap()

        let testImage = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        let done = app.buttons[AccessibilityIdentifiers.Capture.doneButton]
        XCTAssertTrue(testImage.waitForExistence(timeout: 5), "Batch capture should provide Use Test Image")
        XCTAssertTrue(testImage.isHittable, "Batch capture action should remain reachable")
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Batch capture should provide Done")
        XCTAssertTrue(done.isHittable, "Batch Done action should remain reachable")

        testImage.tap()

        let thumbnail = app.buttons[AccessibilityIdentifiers.Capture.thumbnail].firstMatch
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 8), "Captured batch page should create a thumbnail")
        XCTAssertTrue(thumbnail.isHittable, "Captured page thumbnail should remain reachable")
        captureScreenshot(named: "accessibility_text_batch_capture", description: "Batch capture at accessibility text size")
    }

    private func reveal(_ element: XCUIElement) -> Bool {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}
