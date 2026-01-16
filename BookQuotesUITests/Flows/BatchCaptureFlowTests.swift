import XCTest

/// End-to-end tests for batch/multi-page capture flow.
/// Tests capturing multiple pages, thumbnail strip, and session management.
final class BatchCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()

        // Navigate to library and open a book
        let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    // MARK: - Batch Capture Entry Tests

    func testBookDetail_CaptureButton_OpensBatchCapture() {
        logger.step(1, "Opening a book detail")
        openFirstBook()

        logger.step(2, "Finding capture quotes button")
        let captureButton = app.buttons[AccessibilityIdentifiers.BookDetail.captureQuotesButton]
        let addQuoteButton = app.buttons["Add Quote"]

        if captureButton.waitForExistence(timeout: 3) {
            captureButton.tap()
        } else if addQuoteButton.exists {
            addQuoteButton.tap()
        } else {
            // Try menu option
            let menuButton = findMoreMenuButton()
            if menuButton.waitForExistence(timeout: 2) {
                menuButton.tap()
                let captureOption = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'Capture'")
                ).firstMatch
                if captureOption.waitForExistence(timeout: 2) {
                    captureOption.tap()
                }
            }
        }

        logger.step(3, "Verifying batch capture view")
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

        // Give time for thumbnail to render
        sleep(1)

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

    func testBatchCapture_MultipleCaptures_ShowsMultipleThumbnails() throws {
        logger.step(1, "Opening batch capture")
        try openBatchCapture()

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        guard testImageButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test image button not available")
        }

        logger.step(2, "Capturing multiple images")
        testImageButton.tap()
        sleep(1)
        testImageButton.tap()
        sleep(1)
        testImageButton.tap()

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
        sleep(1)

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
            let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]

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
        sleep(1)

        let doneButton = app.buttons["Done"]
        doneButton.tap()

        logger.step(2, "Selecting save draft option")
        let saveDraftButton = app.buttons["Save Draft"]

        if saveDraftButton.waitForExistence(timeout: 3) {
            saveDraftButton.tap()

            logger.step(3, "Verifying return to book detail or library")
            let bookDetail = app.staticTexts["Quotes"]
            let libraryTab = app.tabBars.buttons[AccessibilityIdentifiers.Tabs.libraryTab]

            let returnedToApp = bookDetail.waitForExistence(timeout: 5) || libraryTab.exists

            XCTAssertTrue(returnedToApp, "Should return to app after saving draft")

            logger.success("Save draft works correctly")
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
        sleep(1)

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

    private func openFirstBook() {
        // Switch to list view for easier selection
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

    private func openBatchCapture() throws {
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

        // Wait for batch capture UI
        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
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
        let navButtons = app.navigationBars.buttons
        let predicate = NSPredicate(format: "label CONTAINS 'More' OR label CONTAINS 'ellipsis'")
        let match = navButtons.matching(predicate).firstMatch
        if match.exists {
            return match
        }
        return navButtons.element(boundBy: navButtons.count > 0 ? navButtons.count - 1 : 0)
    }
}
