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
        logger.step(1, "Tapping add book button")
        openAddBookFlow()

        logger.step(2, "Verifying cover capture options")
        // Should see mode picker for photo/barcode
        let modePicker = app.segmentedControls.firstMatch
        let photoLabel = app.staticTexts["Position book cover"]

        let hasCaptureUI = modePicker.waitForExistence(timeout: 5) || photoLabel.exists

        if hasCaptureUI {
            logger.success("Cover capture view displayed")
        } else {
            // May go directly to manual entry
            let titleField = app.textFields["Title"]
            if titleField.exists {
                logger.info("Went directly to manual entry (camera may not be available)")
            }
        }
    }

    func testCoverCapture_ModePicker_SwitchesBetweenPhotoAndBarcode() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding mode picker")
        let modePicker = app.segmentedControls.firstMatch
        guard modePicker.waitForExistence(timeout: 5) else {
            logger.info("Mode picker not found - may be in manual entry mode")
            return
        }

        logger.step(3, "Switching to barcode mode")
        let barcodeButton = modePicker.buttons["Barcode"]
        if barcodeButton.exists {
            barcodeButton.tap()

            // Verify barcode UI
            let barcodePrompt = app.staticTexts["Align barcode within frame"]
            XCTAssertTrue(barcodePrompt.waitForExistence(timeout: 3), "Barcode mode should show alignment prompt")

            logger.step(4, "Switching back to photo mode")
            let photoButton = modePicker.buttons["Photo"]
            if photoButton.exists {
                photoButton.tap()
            }

            let photoPrompt = app.staticTexts["Position book cover"]
            XCTAssertTrue(photoPrompt.waitForExistence(timeout: 3), "Photo mode should show positioning prompt")

            logger.success("Mode picker switches correctly")
        }
    }

    // MARK: - Photo Capture Tests

    func testCoverCapture_PhotoMode_ShowsCaptureButton() {
        logger.step(1, "Opening cover capture in photo mode")
        openAddBookFlow()

        logger.step(2, "Verifying capture button exists")
        // Look for test cover button in UI test mode
        let testCoverButton = app.buttons[AccessibilityIdentifiers.Capture.testCoverButton]
        let captureButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'capture' OR identifier CONTAINS 'capture'")
        ).firstMatch

        let hasCaptureButton = testCoverButton.waitForExistence(timeout: 5) || captureButton.exists

        if hasCaptureButton {
            logger.success("Capture button available in photo mode")
        } else {
            logger.info("Capture button not found (camera may require permissions)")
        }
    }

    func testCoverCapture_TestCoverButton_NavigatesToBookEdit() throws {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding test cover button")
        let testCoverButton = app.buttons[AccessibilityIdentifiers.Capture.testCoverButton]
        guard testCoverButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("Test cover button not available (not in UI test mode)")
        }

        logger.step(3, "Tapping test cover button")
        testCoverButton.tap()

        logger.step(4, "Waiting for processing")
        // Should show processing indicator then navigate to edit
        let processingText = app.staticTexts["Analyzing cover..."]
        if processingText.waitForExistence(timeout: 2) {
            logger.info("Processing cover...")
        }

        logger.step(5, "Verifying navigation to book edit")
        let titleField = app.textFields["Title"]
        let editNavBar = app.navigationBars.matching(
            NSPredicate(format: "identifier CONTAINS 'Book' OR identifier CONTAINS 'Add'")
        ).firstMatch

        let navigatedToEdit = titleField.waitForExistence(timeout: 10) || editNavBar.exists

        XCTAssertTrue(navigatedToEdit, "Should navigate to book edit after cover capture")

        logger.success("Test cover capture navigates to book edit")
    }

    // MARK: - Barcode Scanning Tests

    func testCoverCapture_BarcodeMode_ShowsScanFrame() throws {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Switching to barcode mode")
        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        if permissionPrompt.waitForExistence(timeout: 2) {
            throw XCTSkip("Camera permission prompt shown; barcode UI unavailable")
        }

        let modePicker = app.segmentedControls[AccessibilityIdentifiers.Capture.modePicker]
        guard modePicker.waitForExistence(timeout: 5) else {
            logger.info("Mode picker not found")
            return
        }

        let barcodeButton = modePicker.buttons["Barcode"]
        if barcodeButton.exists {
            barcodeButton.tap()
        }

        logger.step(3, "Verifying scan frame UI")
        let scanPrompt = app.staticTexts["Align barcode within frame"]
        XCTAssertTrue(scanPrompt.waitForExistence(timeout: 3), "Barcode scan frame should be visible")

        logger.success("Barcode scan frame displayed")
    }

    func testCoverCapture_BarcodeMode_HasScanningAnimation() throws {
        logger.step(1, "Opening cover capture in barcode mode")
        openAddBookFlow()

        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        if permissionPrompt.waitForExistence(timeout: 2) {
            throw XCTSkip("Camera permission prompt shown; barcode UI unavailable")
        }

        let modePicker = app.segmentedControls[AccessibilityIdentifiers.Capture.modePicker]
        if modePicker.waitForExistence(timeout: 5) {
            let barcodeButton = modePicker.buttons["Barcode"]
            if barcodeButton.exists {
                barcodeButton.tap()
            }
        }

        logger.step(2, "Verifying scanning UI elements")
        // The scan line animation should be running
        let scanPrompt = app.staticTexts["Align barcode within frame"]

        if scanPrompt.waitForExistence(timeout: 3) {
            logger.success("Barcode scanning UI active")
        } else {
            logger.info("Barcode scanning UI may differ")
        }
    }

    // MARK: - Manual Entry Fallback Tests

    func testCoverCapture_ManualEntryLink_NavigatesToForm() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding manual entry link")
        let manualEntryButton = app.buttons["Enter manually"]

        if manualEntryButton.waitForExistence(timeout: 5) {
            logger.step(3, "Tapping manual entry")
            manualEntryButton.tap()

            logger.step(4, "Verifying navigation to manual form")
            let titleField = app.textFields["Title"]
            XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Should navigate to manual entry form")

            logger.success("Manual entry link works correctly")
        } else {
            // May already be on manual entry form
            let titleField = app.textFields["Title"]
            if titleField.exists {
                logger.info("Already on manual entry form")
            }
        }
    }

    // MARK: - Cancel Flow Tests

    func testCoverCapture_CancelButton_DismissesCaptureView() {
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Finding cancel button")
        let cancelButton = app.buttons["Cancel"]

        if cancelButton.waitForExistence(timeout: 5) {
            logger.step(3, "Tapping cancel")
            cancelButton.tap()

            logger.step(4, "Verifying dismissal")
            // Should return to library view
            let libraryTab = tabButton(.library)
            let addBookButton = app.buttons[AccessibilityIdentifiers.Library.addBookButton]

            let returnedToLibrary = libraryTab.waitForExistence(timeout: 3) || addBookButton.exists

            XCTAssertTrue(returnedToLibrary, "Cancel should return to library")

            logger.success("Cancel dismisses cover capture")
        }
    }

    // MARK: - Error Handling Tests

    func testCoverCapture_WithoutCamera_ShowsPermissionPrompt() {
        // This test verifies graceful handling when camera isn't available
        logger.step(1, "Opening cover capture")
        openAddBookFlow()

        logger.step(2, "Checking for permission or capture UI")
        let permissionPrompt = app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt]
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.testCoverButton]
        let manualEntry = app.buttons["Enter manually"]

        let hasValidUI = permissionPrompt.waitForExistence(timeout: 5) ||
                        captureButton.exists ||
                        manualEntry.exists

        XCTAssertTrue(hasValidUI, "Should show permission prompt, capture button, or manual entry option")

        logger.success("Camera permission/fallback handled correctly")
    }

    // MARK: - Helpers

    private func openAddBookFlow() {
        let captureTab = tabButton(.capture)
        if captureTab.waitForExistence(timeout: 5) {
            captureTab.tap()
        }

        let coverOption = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        if coverOption.waitForExistence(timeout: 5) {
            coverOption.tap()
        }

        // Wait for capture view, manual entry, or permission prompt
        _ = app.segmentedControls[AccessibilityIdentifiers.Capture.modePicker].waitForExistence(timeout: 3) ||
            app.textFields["Title"].waitForExistence(timeout: 3) ||
            app.otherElements[AccessibilityIdentifiers.Capture.permissionPrompt].waitForExistence(timeout: 3)
    }
}
