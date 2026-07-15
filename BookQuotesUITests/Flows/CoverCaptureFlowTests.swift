import XCTest

/// End-to-end coverage for ISBN-first book registration and manual fallback.
final class CoverCaptureFlowTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        ["--preload-library-test-data", "--mock-camera"]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        let libraryTab = tabButton(.library)
        if libraryTab.waitForExistence(timeout: 5) {
            libraryTab.tap()
        }
    }

    func testAddBookStartsInISBNScanner() {
        openAddBookFlow()

        XCTAssertTrue(cameraPreview.exists, "ISBN registration should show the live camera preview")
        XCTAssertTrue(scanFrame.exists, "ISBN registration should show the barcode frame immediately")
        XCTAssertTrue(barcodeInstruction.exists, "ISBN registration should explain barcode alignment")
        XCTAssertFalse(
            app.segmentedControls[AccessibilityIdentifiers.Capture.modePicker].exists,
            "Book registration should not offer the removed cover-photo AI mode"
        )
        XCTAssertFalse(captureButton.exists, "ISBN registration should not show a cover-photo shutter")
        XCTAssertEqual(manualEntryButton.label, "Enter book details manually")
    }

    func testTestISBNPrefillsCatalogMetadata() {
        openAddBookFlow()

        XCTAssertTrue(testISBNButton.waitForExistence(timeout: 5))
        testISBNButton.tap()

        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
        let authorField = app.textFields[AccessibilityIdentifiers.BookEdit.authorField]
        let isbnField = app.textFields[AccessibilityIdentifiers.BookEdit.isbnField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        XCTAssertEqual(titleField.value as? String, "Test ISBN Book")
        XCTAssertEqual(authorField.value as? String, "Test Author")
        XCTAssertEqual(isbnField.value as? String, "9780735211292")
    }

    func testISBNMetadataCanCreateBook() {
        executionTimeAllowance = 180
        openAddBookFlow()
        testISBNButton.tap()

        let titleField = app.textFields[AccessibilityIdentifiers.BookEdit.titleField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        let title = "ISBN Book \(UUID().uuidString.prefix(8))"
        replaceText(title, in: titleField)

        let saveButton = app.buttons[AccessibilityIdentifiers.BookEdit.saveButton]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 6))
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        let detailTitle = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 8))
        XCTAssertEqual(detailTitle.label, title)
    }

    func testManualEntryFallbackOpensBookForm() {
        openAddBookFlow()

        XCTAssertTrue(manualEntryButton.waitForExistence(timeout: 5))
        XCTAssertEqual(manualEntryButton.label, "Enter book details manually")
        manualEntryButton.tap()

        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.BookEdit.titleField].waitForExistence(timeout: 5),
            "Manual fallback should open the editable book form"
        )
    }

    func testCancelDismissesISBNScanner() {
        openAddBookFlow()

        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()

        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover].waitForExistence(timeout: 5),
            "Cancelling should return to capture mode selection"
        )
    }

    func testMockCameraDoesNotShowPermissionPrompt() {
        openAddBookFlow()

        XCTAssertFalse(permissionPrompt.waitForExistence(timeout: 2))
        XCTAssertTrue(cameraPreview.exists)
        XCTAssertTrue(scanFrame.exists)
    }

    private func openAddBookFlow() {
        XCTAssertTrue(tapTab(.capture), "Capture tab should be available")

        let coverOption = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        XCTAssertTrue(coverOption.waitForExistence(timeout: 5), "Capture should offer Add New Book")
        coverOption.tap()

        XCTAssertTrue(scanFrame.waitForExistence(timeout: 5), "Add Book should open the ISBN scanner")
        XCTAssertTrue(testISBNButton.waitForExistence(timeout: 5), "UI tests should expose an ISBN result fixture")
    }

    private var cameraPreview: XCUIElement {
        app.otherElements[AccessibilityIdentifiers.Capture.cameraPreview]
    }

    private var captureButton: XCUIElement {
        app.buttons[AccessibilityIdentifiers.Capture.captureButton]
    }

    private var testISBNButton: XCUIElement {
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
}

final class AdaptiveCoverCaptureLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "--mock-camera",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    func testISBNActionsRemainReachableWithAccessibilityText() {
        XCTAssertTrue(tapTab(.capture))

        let coverOption = app.buttons[AccessibilityIdentifiers.Capture.modeSelectCover]
        XCTAssertTrue(coverOption.waitForExistence(timeout: 5))
        XCTAssertTrue(coverOption.isHittable)
        coverOption.tap()

        let scanFrame = app.otherElements[AccessibilityIdentifiers.Capture.barcodeScanFrame]
        let testISBNButton = app.buttons[AccessibilityIdentifiers.Capture.testCoverButton]
        let manualEntryButton = app.buttons[AccessibilityIdentifiers.Capture.manualEntryButton]
        XCTAssertTrue(scanFrame.waitForExistence(timeout: 5))
        XCTAssertTrue(testISBNButton.waitForExistence(timeout: 5))
        XCTAssertTrue(testISBNButton.isHittable)
        XCTAssertTrue(manualEntryButton.exists && manualEntryButton.isHittable)

        testISBNButton.tap()
        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.BookEdit.titleField].waitForExistence(timeout: 10)
        )
    }
}
