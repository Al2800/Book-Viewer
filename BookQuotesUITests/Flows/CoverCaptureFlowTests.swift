import XCTest

/// End-to-end tests for book cover capture and ISBN scanning flows.
/// Tests cover photo capture, barcode scanning, and manual entry fallback.
final class CoverCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data", "--mock-camera"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()

        // Navigate to library tab
        let libraryTab = tabButton(.library)
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    // MARK: - Cover Capture Navigation Tests

    func testAddBook_ShowsCoverCaptureOptions() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Verifying capture options")
        XCTAssertTrue(modePicker.exists, "Cover capture should offer photo and barcode modes")
        XCTAssertTrue(modePicker.buttons["Photo"].exists, "Photo mode should be available")
        XCTAssertTrue(modePicker.buttons["Barcode"].exists, "Barcode mode should be available")
        XCTAssertTrue(captureButton.exists && captureButton.isEnabled, "Mock camera should provide an enabled shutter")
        XCTAssertTrue(testCoverButton.exists && testCoverButton.isEnabled, "UI tests should provide Use Test Cover")
        XCTAssertTrue(manualEntryButton.exists, "Cover capture should always offer manual entry")

        logger.success("Cover capture options displayed")
    }

    func testCoverCapture_ModePicker_SwitchesBetweenPhotoAndBarcode() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Switching to barcode mode")
        let barcodeButton = modePicker.buttons["Barcode"]
        XCTAssertTrue(barcodeButton.exists, "Cover capture should offer barcode mode")
        barcodeButton.tap()

        XCTAssertTrue(
            app.staticTexts[AccessibilityIdentifiers.Capture.barcodeInstruction].waitForExistence(timeout: 3),
            "Barcode mode should show an alignment instruction"
        )
        XCTAssertTrue(
            app.otherElements[AccessibilityIdentifiers.Capture.barcodeScanFrame].exists,
            "Barcode mode should show a scan frame"
        )
        XCTAssertEqual(manualEntryButton.label, "Enter ISBN manually", "Barcode mode should offer ISBN entry")

        logger.step(3, "Switching back to photo mode")
        let photoButton = modePicker.buttons["Photo"]
        XCTAssertTrue(photoButton.exists, "Cover capture should offer photo mode")
        photoButton.tap()

        XCTAssertTrue(captureButton.waitForExistence(timeout: 3), "Photo mode should restore the shutter")
        XCTAssertTrue(testCoverButton.exists, "Photo mode should restore Use Test Cover")
        XCTAssertEqual(manualEntryButton.label, "Enter details manually", "Photo mode should offer metadata entry")

        logger.success("Mode picker switches correctly")
    }

    // MARK: - Photo Capture Tests

    func testCoverCapture_PhotoMode_ShowsCaptureButton() {
        logger.step(1, "Opening cover capture in photo mode")
        openAddBookFlow()

        logger.step(2, "Verifying camera controls")
        XCTAssertTrue(cameraPreview.exists, "Mock camera should render a camera preview surface")
        XCTAssertTrue(captureButton.exists && captureButton.isEnabled, "Photo mode should provide an enabled shutter")
        XCTAssertTrue(testCoverButton.exists && testCoverButton.isEnabled, "Photo mode should provide Use Test Cover")

        logger.success("Capture button available in photo mode")
    }

    func testCoverCapture_TestCoverButton_NavigatesToBookEdit() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding test cover button")
        XCTAssertTrue(testCoverButton.waitForExistence(timeout: 5), "Mock cover capture should provide Use Test Cover")

        logger.step(3, "Tapping test cover button")
        testCoverButton.tap()

        logger.step(4, "Accepting the test cover crop")
        acceptCoverCrop()

        logger.step(5, "Verifying navigation to book edit")
        assertBookEditShowsTestCoverMetadata()

        logger.success("Test cover capture navigates to book edit")
    }

    func testCoverCapture_CropAccept_DismissesReviewBeforeProcessing() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Capturing mock cover photo")
        XCTAssertTrue(captureButton.waitForExistence(timeout: 5), "Mock cover capture should provide an enabled shutter")
        XCTAssertTrue(captureButton.isEnabled, "Mock cover shutter should be enabled")
        captureButton.tap()

        logger.step(3, "Accepting crop review")
        let useCropButton = acceptCoverCrop()

        logger.step(4, "Verifying crop review reaches book edit")

        let leftCropReview = waitUntil("Crop review should dismiss", timeout: 5) {
            !useCropButton.exists
        }
        XCTAssertTrue(leftCropReview, "Crop review should dismiss after accepting crop")
        assertBookEditShowsTestCoverMetadata()

        logger.success("Crop accept dismisses review before processing")
    }

    func testCoverCapture_TestCoverButton_CanSaveBook() {
        executionTimeAllowance = 180
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Using test cover")
        XCTAssertTrue(testCoverButton.waitForExistence(timeout: 5), "Mock cover capture should provide Use Test Cover")
        testCoverButton.tap()
        acceptCoverCrop()

        logger.step(3, "Filling required fields on book edit")
        let suffix = String(UUID().uuidString.prefix(8))
        let titleToUse = "Cover Book \(suffix)"

        let titleFieldById = app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
        XCTAssertTrue(titleFieldById.waitForExistence(timeout: 10), "Book edit form should open after using test cover")
        replaceText(titleToUse, in: titleFieldById)

        logger.step(4, "Saving book")
        let saveButtonById = app.buttons[AccessibilityIdentifiers.BookEdit.saveButton]
        XCTAssertTrue(saveButtonById.waitForExistence(timeout: 6), "Book edit should provide Add Book")
        XCTAssertTrue(saveButtonById.isEnabled, "Prefilled cover metadata should be saveable")
        saveButtonById.tap()

        logger.step(5, "Verifying book was created")
        XCTAssertTrue(
            app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].waitForExistence(timeout: 8),
            "Saving a captured cover should open the new book"
        )
        XCTAssertEqual(
            app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].label,
            titleToUse,
            "The created book detail should show the saved title"
        )

        logger.success("Cover capture flow can create a book")
    }

    // MARK: - Barcode Scanning Tests

    func testCoverCapture_BarcodeMode_ShowsScanFrame() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Switching to barcode mode")
        XCTAssertFalse(permissionPrompt.waitForExistence(timeout: 2), "Mock camera should not request permission")

        let barcodeButton = modePicker.buttons["Barcode"]
        XCTAssertTrue(barcodeButton.exists, "Cover capture should offer barcode mode")
        barcodeButton.tap()

        logger.step(3, "Verifying scan frame UI")
        XCTAssertTrue(scanFrame.waitForExistence(timeout: 3), "Barcode mode should show a scan frame")
        XCTAssertTrue(barcodeInstruction.exists, "Barcode mode should show an alignment instruction")

        logger.success("Barcode scan frame displayed")
    }

    func testCoverCapture_BarcodeMode_OffersManualISBNEntry() {
        logger.step(1, "Opening cover capture in barcode mode")
        openAddBookFlow()

        XCTAssertFalse(permissionPrompt.waitForExistence(timeout: 2), "Mock camera should not request permission")

        let barcodeButton = modePicker.buttons["Barcode"]
        XCTAssertTrue(barcodeButton.exists, "Cover capture should offer barcode mode")
        barcodeButton.tap()

        logger.step(2, "Opening manual ISBN entry")
        XCTAssertTrue(manualEntryButton.waitForExistence(timeout: 3), "Barcode mode should offer manual ISBN entry")
        XCTAssertEqual(manualEntryButton.label, "Enter ISBN manually", "Barcode mode should label the fallback clearly")
        manualEntryButton.tap()

        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.BookEdit.isbnField].waitForExistence(timeout: 5),
            "Manual ISBN entry should open the book form"
        )

        logger.success("Manual ISBN entry is available")
    }

    // MARK: - Manual Entry Fallback Tests

    func testCoverCapture_ManualEntryLink_NavigatesToForm() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding manual entry link")
        XCTAssertTrue(manualEntryButton.waitForExistence(timeout: 5), "Cover capture should offer manual entry")
        XCTAssertEqual(manualEntryButton.label, "Enter details manually", "Photo mode should label the fallback clearly")

        logger.step(3, "Tapping manual entry")
        manualEntryButton.tap()

        logger.step(4, "Verifying navigation to manual form")
        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.BookEdit.titleField].waitForExistence(timeout: 5),
            "Manual entry should open the book form"
        )

        logger.success("Manual entry link works correctly")
    }

    // MARK: - Cancel Flow Tests

    func testCoverCapture_CancelButton_DismissesCaptureView() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding cancel button")
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Cover capture should provide Cancel")

        logger.step(3, "Tapping cancel")
        cancelButton.tap()

        logger.step(4, "Verifying dismissal")
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover].waitForExistence(timeout: 5),
            "Cancelling cover capture should return to capture mode selection"
        )

        logger.success("Cancel dismisses cover capture")
    }

    // MARK: - Error Handling Tests

    func testCoverCapture_MockCamera_DoesNotShowPermissionPrompt() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Checking mocked camera state")
        XCTAssertFalse(permissionPrompt.waitForExistence(timeout: 2), "Mocked camera should bypass the permission prompt")
        XCTAssertTrue(cameraPreview.exists, "Mocked camera should provide the preview surface")
        XCTAssertTrue(captureButton.exists, "Mocked camera should provide the shutter")

        logger.success("Mock camera is configured correctly")
    }

    // MARK: - Helpers

    private func openAddBookFlow() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let coverOption = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        XCTAssertTrue(coverOption.waitForExistence(timeout: 5), "Capture should offer cover mode")
        coverOption.tap()

        XCTAssertTrue(modePicker.waitForExistence(timeout: 5), "Cover mode should open the photo and barcode picker")
        XCTAssertTrue(testCoverButton.waitForExistence(timeout: 5), "Cover mode should provide the UI-test cover fixture")
    }

    private var modePicker: XCUIElement {
        app.segmentedControls[AccessibilityIdentifiers.Capture.modePicker]
    }

    private var cameraPreview: XCUIElement {
        app.otherElements[AccessibilityIdentifiers.Capture.cameraPreview]
    }

    private var captureButton: XCUIElement {
        app.buttons[AccessibilityIdentifiers.Capture.captureButton]
    }

    private var testCoverButton: XCUIElement {
        app.buttons[AccessibilityIdentifiers.Capture.testCoverButton]
    }

    private var manualEntryButton: XCUIElement {
        app.buttons[AccessibilityIdentifiers.Capture.manualEntryButton]
    }

    private var cancelButton: XCUIElement {
        app.buttons[AccessibilityIdentifiers.Capture.cancelButton]
    }

    private var permissionPrompt: XCUIElement {
        app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
    }

    private var scanFrame: XCUIElement {
        app.otherElements[AccessibilityIdentifiers.Capture.barcodeScanFrame]
    }

    private var barcodeInstruction: XCUIElement {
        app.staticTexts[AccessibilityIdentifiers.Capture.barcodeInstruction]
    }

    private func assertBookEditShowsTestCoverMetadata() {
        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
        let authorField = app.textFields[AccessibilityIdentifiers.BookEdit.authorField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10), "Cover capture should open the book edit form")
        XCTAssertEqual(titleField.value as? String, "Test Cover Book", "Mock cover metadata should prefill the extracted title")
        XCTAssertEqual(authorField.value as? String, "Test Author", "Mock cover metadata should prefill the extracted author")
    }

    @discardableResult
    private func acceptCoverCrop() -> XCUIElement {
        let useCropButton = app.buttons[AccessibilityIdentifiers.CoverCrop.useCropButton]
        XCTAssertTrue(useCropButton.waitForExistence(timeout: 7), "Mock cover capture should present crop review")
        useCropButton.tap()
        return useCropButton
    }
}

/// Regression coverage for cover capture at the largest supported text size.
final class AdaptiveCoverCaptureLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    func testCoverCaptureActionsRemainReachableWithAccessibilityText() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let coverOption = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        XCTAssertTrue(coverOption.waitForExistence(timeout: 5), "Capture should offer cover mode")
        XCTAssertTrue(coverOption.isHittable, "Cover mode should remain reachable at accessibility text sizes")
        coverOption.tap()

        let modePicker = app.segmentedControls[AccessibilityIdentifiers.Capture.modePicker]
        let testCoverButton = app.buttons[AccessibilityIdentifiers.Capture.testCoverButton]
        let manualEntryButton = app.buttons[AccessibilityIdentifiers.Capture.manualEntryButton]
        XCTAssertTrue(modePicker.waitForExistence(timeout: 5), "Photo and barcode modes should remain visible")
        XCTAssertTrue(testCoverButton.waitForExistence(timeout: 5), "Use Test Cover should remain visible")
        XCTAssertTrue(testCoverButton.isHittable, "Use Test Cover should remain reachable")
        XCTAssertTrue(manualEntryButton.exists && manualEntryButton.isHittable, "Manual entry should remain reachable")
        captureScreenshot(
            named: "accessibility_text_cover_capture",
            description: "Cover capture controls at accessibility text size"
        )

        testCoverButton.tap()
        let useCropButton = app.buttons[AccessibilityIdentifiers.CoverCrop.useCropButton]
        XCTAssertTrue(useCropButton.waitForExistence(timeout: 7), "Crop review should open")
        XCTAssertTrue(useCropButton.isHittable, "Crop confirmation should remain reachable")
        useCropButton.tap()

        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.BookEdit.titleField].waitForExistence(timeout: 10),
            "Accepting the cover should open the book form"
        )
    }
}
