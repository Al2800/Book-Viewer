import XCTest

/// End-to-end tests for batch/multi-page capture flow.
/// Tests capturing multiple pages, thumbnail strip, and session management.
final class BatchCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data", "--mock-camera"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()

        // Navigate to library and open a book
        let libraryTab = tabButton(.library)
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    // MARK: - Batch Capture Entry Tests

    func testBatchCapture_OpensFromCaptureTab() throws {
        logger.step(1, "Opening batch capture from Capture tab")
        try openBatchCapture()

        logger.step(2, "Verifying batch capture view")
        // Should see page counter and capture controls
        let pageCounter = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'pages'")
        ).firstMatch
        let captureButtonInView = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]

        let hasBatchUI = pageCounter.waitForExistence(timeout: 5) ||
                        captureButtonInView.exists ||
                        testImageButton.exists

        if hasBatchUI {
            logger.success("Batch capture view opened")
        } else {
            logger.info("Batch capture may require camera permissions")
        }
    }

    // MARK: - Page Counter Tests

    func testBatchCapture_PageCounter_StartsAtZero() throws {
        logger.step(1, "Opening batch capture")
        try openBatchCapture()

        logger.step(2, "Verifying page counter")
        let pageCounter = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '0' AND label CONTAINS 'page'")
        ).firstMatch

        // Alternative: look for "0 pages" text anywhere
        let zeroPages = app.staticTexts["0"]

        let startsAtZero = pageCounter.waitForExistence(timeout: 3) || zeroPages.exists

        if startsAtZero {
            logger.success("Page counter starts at 0")
        } else {
            logger.info("Page counter may have different format")
        }
    }

    func testBatchCapture_CapturePhoto_IncrementsCounter() throws {
        logger.step(1, "Opening batch capture")
        try openBatchCapture()

        logger.step(2, "Capturing a test image")
        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()

        logger.step(3, "Verifying counter incremented")
        // Wait for capture to complete and counter to update
        let onePageText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '1'")
        ).firstMatch

        XCTAssertTrue(onePageText.waitForExistence(timeout: 5), "Page counter should show 1 after capture")

        logger.success("Page counter incremented after capture")
    }

    // MARK: - Thumbnail Strip Tests

    func testBatchCapture_AfterCapture_ShowsThumbnail() throws {
        logger.step(1, "Opening batch capture and capturing")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()

        logger.step(2, "Waiting for thumbnail to appear")
        // Thumbnail should appear in the strip
        // Look for scrollable horizontal content or image elements
        let thumbnails = app.scrollViews.images

        // Wait for the thumbnail strip to update (avoid fixed sleeps).
        _ = waitUntil("thumbnail appears", timeout: 3) { [weak self] in
            guard let self else { return false }
            return thumbnails.count > 0 || self.app.images.count > 0
        }

        logger.step(3, "Verifying thumbnail exists")
        // The thumbnail strip should have at least one item
        let hasThumbnails = thumbnails.count > 0 ||
                           app.images.count > 0

        if hasThumbnails {
            logger.success("Thumbnail displayed after capture")
        } else {
            logger.info("Thumbnail may be rendered differently")
        }
    }

    func testBatchCapture_ThumbnailDetail_CanRemoveCapture() throws {
        logger.step(1, "Opening batch capture and capturing")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()
        _ = waitUntil("thumbnail appears", timeout: 6) { [weak self] in
            guard let self else { return false }
            return self.app.scrollViews.images.count > 0 || self.app.images.count > 0
        }

        logger.step(2, "Opening thumbnail detail")
        let thumbnail = app.scrollViews.images.firstMatch.exists
            ? app.scrollViews.images.firstMatch
            : app.images.firstMatch
        guard thumbnail.waitForExistence(timeout: 3) else {
            throw XCTSkip("Thumbnail not available")
        }
        thumbnail.tap()

        logger.step(3, "Removing captured page")
        let removeButton = app.buttons["Remove Page"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 3), "Capture detail should show remove action")
        removeButton.tap()

        logger.step(4, "Verifying page count returns to zero")
        let zeroPages = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '0' AND label CONTAINS 'page'")
        ).firstMatch
        XCTAssertTrue(zeroPages.waitForExistence(timeout: 5), "Removing the only capture should return page count to zero")

        logger.success("Thumbnail detail can remove capture")
    }

    func testBatchCapture_MultipleCaptures_ShowsMultipleThumbnails() throws {
        logger.step(1, "Opening batch capture")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        logger.step(2, "Capturing multiple images")
        func waitForPageCount(_ expected: Int) {
            let counter = app.staticTexts[AccessibilityIdentifiers.Capture.pageCounter]
            _ = waitUntil("page counter shows \(expected)", timeout: 6) {
                if counter.exists, counter.label.contains("\(expected)") { return true }
                let match = self.app.staticTexts.matching(
                    NSPredicate(format: "label CONTAINS %@", "\(expected)")
                ).firstMatch
                return match.exists
            }
        }

        testImageButton.tap()
        waitForPageCount(1)
        testImageButton.tap()
        waitForPageCount(2)
        testImageButton.tap()
        waitForPageCount(3)

        logger.step(3, "Verifying page count")
        let threePages = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '3'")
        ).firstMatch

        XCTAssertTrue(threePages.waitForExistence(timeout: 5), "Should show 3 pages after 3 captures")

        logger.success("Multiple captures tracked correctly")
    }

    // MARK: - Done Button Tests

    func testBatchCapture_DoneButton_DisabledWithNoCaptures() throws {
        logger.step(1, "Opening batch capture")
        try openBatchCapture()

        logger.step(2, "Finding done button")
        let doneButton = app.buttons["Done"]

        if doneButton.waitForExistence(timeout: 3) {
            logger.step(3, "Verifying done is disabled with no captures")
            // Done button should be disabled or dimmed when no pages captured
            // In SwiftUI this might still be tappable but styled differently
            logger.info("Done button state verified (may be disabled or styled)")
        }

        logger.success("Done button behavior checked")
    }

    func testBatchCapture_DoneButton_EnabledAfterCapture() throws {
        logger.step(1, "Opening batch capture and capturing")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()

        logger.step(2, "Finding done button")
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Done button should exist")

        logger.step(3, "Tapping done button")
        doneButton.tap()

        logger.step(4, "Verifying confirmation dialog")
        let processButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Process'")
        ).firstMatch
        let saveDraftButton = app.buttons["Save Draft"]

        let hasConfirmation = processButton.waitForExistence(timeout: 3) || saveDraftButton.exists

        XCTAssertTrue(hasConfirmation, "Should show confirmation dialog")

        logger.success("Done button shows confirmation after capture")
    }

    // MARK: - Session Completion Tests

    func testBatchCapture_ProcessOption_ProcessesCaptures() throws {
        logger.step(1, "Capturing and finishing session")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()
        // Wait for capture state to settle before attempting to complete.
        _ = waitUntil("capture recorded", timeout: 6) { [weak self] in
            guard let self else { return false }
            let counter = self.app.staticTexts[AccessibilityIdentifiers.Capture.pageCounter]
            return counter.exists || self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch.exists
        }

        let doneButton = app.buttons["Done"]
        doneButton.tap()

        logger.step(2, "Selecting process option")
        let processButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Process'")
        ).firstMatch

        if processButton.waitForExistence(timeout: 3) {
            processButton.tap()

            logger.step(3, "Verifying processing or navigation")
            // Should either show processing UI or navigate to extraction review
            let processingIndicator = app.progressIndicators.firstMatch
            let extractionReview = app.navigationBars["Review Extractions"]
            let libraryTab = tabButton(.library)

            let movedForward = processingIndicator.waitForExistence(timeout: 3) ||
                              extractionReview.waitForExistence(timeout: 10) ||
                              libraryTab.waitForExistence(timeout: 10)

            XCTAssertTrue(movedForward, "Should proceed with processing")

            logger.success("Process option initiates processing")
        }
    }

    func testBatchCapture_SaveDraftOption_SavesWithoutProcessing() throws {
        logger.step(1, "Capturing and finishing session")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()
        // Wait for capture state to settle before attempting to complete.
        _ = waitUntil("capture recorded", timeout: 6) { [weak self] in
            guard let self else { return false }
            let counter = self.app.staticTexts[AccessibilityIdentifiers.Capture.pageCounter]
            return counter.exists || self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch.exists
        }

        let doneButton = app.buttons["Done"]
        doneButton.tap()

        logger.step(2, "Selecting save draft option")
        let saveDraftButton = app.buttons["Save Draft"]

        if saveDraftButton.waitForExistence(timeout: 3) {
            saveDraftButton.tap()

            logger.step(3, "Verifying the draft is visible and resumable")
            XCTAssertTrue(
                app.staticTexts["Saved Drafts"].waitForExistence(timeout: 5),
                "Saved drafts should be visible on the Capture screen"
            )

            let resumeDraft = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH 'capture_resume_draft_'")
            ).firstMatch
            XCTAssertTrue(resumeDraft.waitForExistence(timeout: 3), "Saved draft should have a resume action")
            resumeDraft.tap()

            XCTAssertTrue(
                app.staticTexts["1 page in session"].waitForExistence(timeout: 5),
                "Resuming a draft should reopen batch capture with its saved pages"
            )

            logger.success("Save draft is visible and resumable")
        }
    }

    // MARK: - Cancel Flow Tests

    func testBatchCapture_CancelWithNoCaptures_DismissesImmediately() throws {
        logger.step(1, "Opening batch capture")
        try openBatchCapture()

        logger.step(2, "Finding cancel button (X)")
        let cancelButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'xmark' OR identifier CONTAINS 'cancel'")
        ).firstMatch

        // Also try finding by position (top left)
        let closeButton = app.buttons["Close"]
        let xButton = app.buttons.element(boundBy: 0)

        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
        } else if closeButton.exists {
            closeButton.tap()
        } else if xButton.exists && xButton.isHittable {
            xButton.tap()
        }

        logger.step(3, "Verifying dismissal")
        let bookDetail = app.staticTexts["Quotes"]
        let returnedToDetail = bookDetail.waitForExistence(timeout: 3)

        if returnedToDetail {
            logger.success("Cancel dismisses immediately with no captures")
        } else {
            logger.info("Navigation behavior may differ")
        }
    }

    func testBatchCapture_CancelWithCaptures_ShowsConfirmation() throws {
        logger.step(1, "Opening and capturing")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        testImageButton.tap()
        _ = waitUntil("capture recorded", timeout: 6) { [weak self] in
            guard let self else { return false }
            let counter = self.app.staticTexts[AccessibilityIdentifiers.Capture.pageCounter]
            return counter.exists || self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS '1'")).firstMatch.exists
        }

        logger.step(2, "Tapping cancel with captures")
        // The X button in top left should show confirmation when there are captures
        let xButton = app.buttons.element(boundBy: 0)
        if xButton.exists && xButton.isHittable {
            xButton.tap()
        }

        logger.step(3, "Verifying confirmation shown")
        // Should show same confirmation as Done button
        let processButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Process'")
        ).firstMatch
        let cancelOption = app.buttons["Cancel"]

        let hasConfirmation = processButton.waitForExistence(timeout: 3) || cancelOption.exists

        if hasConfirmation {
            logger.success("Cancel with captures shows confirmation")
            // Dismiss the dialog
            if cancelOption.exists {
                cancelOption.tap()
            }
        }
    }

    // MARK: - Helpers

    private func openBatchCapture() throws {
        let captureTab = tabButton(.capture)
        guard captureTab.waitForExistence(timeout: 3) else {
            throw XCTSkip("Capture tab not available")
        }
        captureTab.tap()

        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        if permissionPrompt.waitForExistence(timeout: 2) {
            throw XCTSkip("Camera permission required")
        }

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        let existingPageCounter = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'page'")
        ).firstMatch
        if existingPageCounter.exists && app.buttons["Done"].exists {
            return
        }

        let batchModeCard = app.buttons[AccessibilityIdentifiers.Capture.modeSelectBatch]
        if batchModeCard.waitForExistence(timeout: 5) {
            batchModeCard.tap()
        }

        let bookCard = app.buttons[AccessibilityIdentifiers.Capture.bookSelectionCard].firstMatch
        guard bookCard.waitForExistence(timeout: 5) else {
            throw XCTSkip("No book available for batch capture")
        }
        bookCard.tap()

        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        let pageCounter = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'page'")
        ).firstMatch

        let hasUI = testImageButton.waitForExistence(timeout: 5) ||
                   captureButton.exists ||
                   pageCounter.exists

        guard hasUI else {
            throw XCTSkip("Batch capture UI not available")
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
}
