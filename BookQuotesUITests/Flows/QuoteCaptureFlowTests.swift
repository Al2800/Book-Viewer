import XCTest

/// End-to-end tests for the quote capture and review flow.
/// Tests camera capture, extraction review, editing, and saving.
final class QuoteCaptureFlowTests: BaseUITestCase {

    // MARK: - Setup

    override var additionalLaunchArguments: [String] {
        var arguments = [
            "--preload-library-test-data",
            "--mock-camera",
            "--mock-extraction-scenario",
            extractionScenario,
            "--product-experience-v2"
        ]
        if name.contains("ReviewDraft") {
            arguments += ["--ui-test-store-id", UUID().uuidString]
        }
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
        XCTAssertTrue(openQuietCaptureFromTab(), "Capture tab should open the live camera")

        logger.step(2, "Verifying capture HUD and batch entry")
        let modeMenu = app.buttons[AccessibilityIdentifiers.Capture.modeMenu]
        XCTAssertTrue(modeMenu.waitForExistence(timeout: 5), "Capture HUD should provide a mode menu")
        captureScreenshot(named: "quiet_capture_camera", description: "Quiet capture live camera with HUD")
        modeMenu.tap()

        let batchMode = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Capture.modeSelectBatch)
            .firstMatch
        let batchLabel = app.buttons["Batch Mode"].firstMatch
        let batchMenuItem = app.menuItems["Batch Mode"].firstMatch
        XCTAssertTrue(
            batchMode.waitForExistence(timeout: 2)
                || batchLabel.waitForExistence(timeout: 2)
                || batchMenuItem.waitForExistence(timeout: 2),
            "Batch capture mode should be available from the HUD menu"
        )

        logger.success("Capture tab displays correctly")
    }

    func testCaptureRoot_PassesSystemAccessibilityAudit() throws {
        XCTAssertTrue(openQuietCaptureFromTab(), "Capture tab should exist")
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.modeMenu].waitForExistence(timeout: 5),
            "Capture HUD should be ready before auditing"
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

    func testQuoteCamera_PassesSystemAccessibilityAudit() throws {
        navigateToCaptureWithBook()
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.testImageButton].waitForExistence(timeout: 5),
            "Mock quote camera should be ready before auditing"
        )
        try performSystemAccessibilityAudit()
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

    // MARK: - Quiet Capture Tests

    func testQuietCapture_PresentsPassagesWithoutImageReview() {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Triggering capture")
        triggerCapture()

        logger.step(3, "Passages should open without a Review Photo gate")
        XCTAssertFalse(
            app.buttons[AccessibilityIdentifiers.ImageReview.usePhotoButton].waitForExistence(timeout: 2),
            "Quiet capture must not present Image Review"
        )
        XCTAssertTrue(
            app.navigationBars["Passages"].waitForExistence(timeout: 15)
                || app.staticTexts["Passages"].waitForExistence(timeout: 2),
            "Passages should present after a usable capture"
        )
        captureScreenshot(named: "quiet_capture_passages", description: "Passages sheet after single-page capture")
        logger.success("Passages presented without Image Review")
    }

    func testQuietCapture_DismissingPassagesReturnsToLiveCamera() {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Taking photo")
        triggerCapture()

        logger.step(3, "Waiting for Passages")
        let passages = app.navigationBars["Passages"]
        XCTAssertTrue(
            passages.waitForExistence(timeout: 15) || app.staticTexts["Passages"].waitForExistence(timeout: 2),
            "Passages should present after capture"
        )

        logger.step(4, "Dismissing Passages")
        let passagesCancel = app.buttons[AccessibilityIdentifiers.Capture.passagesCancelButton]
        XCTAssertTrue(passagesCancel.waitForExistence(timeout: 5), "Passages should expose Cancel")
        passagesCancel.tap()
        let discard = app.alerts.buttons["Discard"]
        if discard.waitForExistence(timeout: 2) {
            discard.tap()
        } else if app.buttons["Discard"].waitForExistence(timeout: 1) {
            app.buttons["Discard"].tap()
        }

        logger.step(5, "Verifying return to live camera")
        let captureButton = app.buttons[AccessibilityIdentifiers.Capture.captureButton]
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertFalse(
            app.navigationBars["Passages"].waitForExistence(timeout: 2),
            "Passages should dismiss after Cancel"
        )
        let returned = waitForHittable(captureButton, timeout: 5) || waitForHittable(testButton, timeout: 2)
        XCTAssertTrue(returned, "Dismissing Passages should return to the live camera")

        logger.success("Dismissing Passages returns to camera")
    }

    func testQuietCapture_PassagesPassesSystemAccessibilityAudit() throws {
        navigateToCaptureWithBook()
        triggerCapture()

        XCTAssertTrue(
            waitForPassagesSheet(),
            "Passages should be ready before auditing"
        )
        try performSystemAccessibilityAudit()
    }

    // MARK: - Extraction Review Tests

    func testExtractionReview_DisplaysExtractedQuotes() {
        logger.step(1, "Navigating to capture")
        navigateToCaptureWithBook()

        logger.step(2, "Capturing and processing")
        triggerCapture()

        logger.step(3, "Waiting for extraction results")
        let editButton = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton]
        let saveButton = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        let modelSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_model_assisted")
            .firstMatch
        let onDeviceSource = app.descendants(matching: .any)
            .matching(identifier: "\(AccessibilityIdentifiers.Capture.extractionQuoteSourceLabel)_on_device")
            .firstMatch
        let failureTitle = app.staticTexts["Extraction Failed"]
        let noQuotesTitle = app.staticTexts["No marked passages found"]
        let remoteConsentButton = app.buttons["Allow Remote AI Processing"]

        XCTAssertTrue(waitForPassagesSheet(), "Extraction review should appear")
        XCTAssertFalse(
            remoteConsentButton.exists,
            "On-device quote review must not be blocked by the optional remote-AI consent sheet"
        )
        XCTAssertFalse(failureTitle.exists, "Extraction should not fail in mock-camera UI smoke")
        XCTAssertFalse(noQuotesTitle.exists, "Mock-camera extraction should return at least one quote")

        let hasExtractedQuoteControls = editButton.waitForExistence(timeout: 10) || saveButton.waitForExistence(timeout: 2)
        XCTAssertTrue(hasExtractedQuoteControls, "Extraction review should show editable extracted quote controls")
        XCTAssertTrue(saveButton.exists && saveButton.isEnabled, "Save to Library should be enabled when mock extraction returns quotes")
        XCTAssertTrue(modelSource.exists, "Review should identify the model-assisted candidate")
        XCTAssertTrue(onDeviceSource.exists, "Review should identify the on-device candidate")
        captureScreenshot(named: "passages_extracted_quotes", description: "Passages sheet with extracted quote cards")

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

        XCTAssertTrue(onDeviceSource.waitForExistence(timeout: 5), "Local-fallback extraction should mark the on-device source")
    }

    func testReviewGuidance_ExplainsScoresAndDoesNotVerifyEdits() {
        navigateToExtractionReview()
        let edit = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton].firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        let text = app.textViews[AccessibilityIdentifiers.Capture.extractionQuoteTextEditor]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap()
        text.typeText(" Reader correction.")
        app.navigationBars["Edit Quote"].buttons["Save"].tap()

        let compare = app.staticTexts["Compare with source"].firstMatch
        XCTAssertTrue(revealForInteraction(compare), "High confidence still requires comparison, not a verified badge")
        let edited = app.staticTexts["Edited by you"].firstMatch
        XCTAssertTrue(revealForInteraction(edited))
        let check = app.staticTexts["Check this passage"].firstMatch
        XCTAssertTrue(revealForInteraction(check), "Uncertainty must be explained in text rather than colour alone")
        XCTAssertTrue(app.staticTexts["On-device"].firstMatch.exists)
        XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].label, "Save 2 passages")
        XCTAssertFalse(app.staticTexts["Verified"].exists)
        XCTAssertFalse(app.staticTexts["94%"].exists)
        if let attachment = screenshots.capture(name: "review_guidance") { add(attachment) }
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

    func testSinglePageReview_ExposesSourceAndCountedSave() {
        navigateToExtractionReview()
        let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.label.hasPrefix("Save ") && save.label.contains("passage"))
        let viewPage = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", AccessibilityIdentifiers.Capture.viewPageButton)).firstMatch
        XCTAssertTrue(viewPage.waitForExistence(timeout: 5))
        viewPage.tap()
        let close = app.buttons["Close image"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5) && save.isEnabled)
    }

    func testReviewSelection_ZeroDisablesSaveAndOnlyIncludedPassageIsSaved() {
        navigateToExtractionReview()
        let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertEqual(save.label, "Save 2 passages")

        let remote = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "A model-assisted quote used for review testing.")).firstMatch
        let local = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "An on-device quote used for review testing.")).firstMatch
        XCTAssertTrue(revealForInteraction(remote))
        remote.tap()
        XCTAssertEqual(save.label, "Save 1 passage")
        XCTAssertTrue(revealForInteraction(local))
        local.tap()
        XCTAssertEqual(save.label, "Save 0 passages")
        XCTAssertFalse(save.isEnabled)
        local.tap()
        XCTAssertEqual(save.label, "Save 1 passage")
        XCTAssertTrue(save.isEnabled)
        save.tap()

        let viewPassages = app.buttons["capture_view_passages_button"]
        XCTAssertTrue(viewPassages.waitForExistence(timeout: 10))
        viewPassages.tap()
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].waitForExistence(timeout: 5))
        let included = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "An on-device quote used for review testing.")).firstMatch
        XCTAssertTrue(revealForInteraction(included), "Selected passage should be in the book")
        let search = app.searchFields.firstMatch
        // The book's search verifies exclusion, rather than relying on an off-screen row being absent.
        for _ in 0..<8 {
            if search.exists && search.isHittable { break }
            app.swipeDown()
        }
        XCTAssertTrue(search.exists && search.isHittable)
        search.tap()
        search.typeText("A model-assisted quote used for review testing.\n")
        XCTAssertTrue(app.staticTexts["No Matching Passages"].waitForExistence(timeout: 5))
    }

    func testReviewDraftSurvivesProcessExitWithoutExplicitKeep() {
        navigateToExtractionReview()
        let first = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "A model-assisted quote used for review testing.")).firstMatch
        XCTAssertTrue(revealForInteraction(first))
        first.tap()
        let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertEqual(save.label, "Save 1 passage")
        app.terminate() // No Cancel/Keep Draft: the completed review change must already be durable.
        app.launch()
        waitForAppReady()
        XCTAssertTrue(tapTab(.capture))
        chooseCaptureModeMenuItem(identifier: AccessibilityIdentifiers.Capture.savedDraftsButton, label: "Saved Drafts (1)")
        let resume = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'capture_resume_draft_'")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.label, "Save 1 passage")
        XCTAssertEqual(first.value as? String, "0")
        let source = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", AccessibilityIdentifiers.Capture.viewPageButton)).firstMatch
        XCTAssertTrue(revealForInteraction(source))
        source.tap()
        XCTAssertTrue(app.buttons["Close image"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["Full source page image"].waitForExistence(timeout: 5),
                      "Actual source pixels, not only the viewer, must survive process exit")
        XCTAssertFalse(app.staticTexts["Image Not Found"].exists)
    }

    func testReviewDraftRestoresEditsManualEntriesAndSelectionAfterRelaunch() {
        navigateToExtractionReview()
        let edit = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton].firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        let text = app.textViews[AccessibilityIdentifiers.Capture.extractionQuoteTextEditor]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap()
        text.typeText(" Restored correction.")
        app.navigationBars["Edit Quote"].buttons["Save"].tap()
        let excluded = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "Restored correction.")).firstMatch
        XCTAssertTrue(revealForInteraction(excluded))
        excluded.tap()

        let add = app.buttons["Add a passage manually"]
        XCTAssertTrue(revealForInteraction(add))
        add.tap()
        let manualText = app.textViews.firstMatch
        XCTAssertTrue(manualText.waitForExistence(timeout: 5))
        manualText.tap()
        manualText.typeText("Manual passage retained across relaunch.")
        app.navigationBars["Add Quote"].buttons["Add"].tap()
        let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.label, "Save 2 passages")
        app.navigationBars["Passages"].buttons[AccessibilityIdentifiers.Capture.passagesCancelButton].tap()
        app.alerts.buttons["Keep Draft"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Capture.testImageButton].waitForExistence(timeout: 5))

        app.terminate()
        app.launch() // Same UUID-namespaced disk store, not an in-memory reseed.
        waitForAppReady()
        XCTAssertTrue(tapTab(.capture))
        chooseCaptureModeMenuItem(identifier: AccessibilityIdentifiers.Capture.savedDraftsButton, label: "Saved Drafts (1)")
        let resume = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'capture_resume_draft_'")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.label, "Save 2 passages")
        XCTAssertTrue(revealForInteraction(excluded))
        XCTAssertEqual(excluded.value as? String, "0")
        let manual = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "Manual passage retained across relaunch.")).firstMatch
        XCTAssertTrue(revealForInteraction(manual))
        XCTAssertEqual(manual.value as? String, "1")
        save.tap()
        XCTAssertTrue(app.buttons["capture_view_passages_button"].waitForExistence(timeout: 8))

        chooseCaptureModeMenuItem(identifier: AccessibilityIdentifiers.Capture.savedDraftsButton, label: "Saved Drafts (1)")
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        resume.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertEqual(save.label, "Save 0 passages", "Saved candidates must not reappear in the retained excluded draft")
        XCTAssertFalse(save.isEnabled)
        XCTAssertTrue(excluded.exists)
        XCTAssertFalse(manual.exists)
    }

    // MARK: - Save Flow Tests

    func testSavePassages_ReturnsToCameraWithOptionalBookNavigation() {
        navigateToExtractionReview()

        logger.step(1, "Finding save button")
        let saveAllButton = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertTrue(saveAllButton.waitForExistence(timeout: 5), "Passages should provide Save to Library")
        XCTAssertTrue(saveAllButton.isEnabled, "Save to Library should be enabled for extracted quotes")
        saveAllButton.tap()

        logger.step(2, "Verifying the continuous camera loop")
        let camera = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(camera.waitForExistence(timeout: 8), "Saving must return to the same-book camera")
        XCTAssertTrue(camera.isEnabled)
        let viewPassages = app.buttons["capture_view_passages_button"]
        XCTAssertTrue(viewPassages.waitForExistence(timeout: 5), "Book navigation must be optional")
        viewPassages.tap()
        let bookDetailTitle = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle]
        XCTAssertTrue(bookDetailTitle.waitForExistence(timeout: 8), "View passages should open the captured book")

        logger.success("Passages saved; camera retained; explicit navigation verified")
    }

    func testContinueReadingCaptureSavesAndReturnsToReading() {
        navigateToLibrary()
        let capture = app.buttons["continue_reading_capture_button"]
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
        let expectedTitle = String(capture.label.dropFirst("Capture passage for ".count))
        XCTAssertFalse(expectedTitle.isEmpty)
        capture.tap()
        let activeBook = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Active Book:'")).firstMatch
        XCTAssertTrue(activeBook.waitForExistence(timeout: 5))
        XCTAssertTrue(activeBook.label.contains(expectedTitle))
        triggerCapture()
        XCTAssertTrue(waitForPassagesSheet())
        let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertTrue(save.waitForExistence(timeout: 5) && save.isEnabled)
        save.tap()
        XCTAssertTrue(app.buttons["capture_view_passages_button"].waitForExistence(timeout: 8))
        XCTAssertTrue(activeBook.label.contains(expectedTitle))
        app.buttons[AccessibilityIdentifiers.Capture.cancelButton].tap()
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
        XCTAssertEqual(capture.label, "Capture passage for \(expectedTitle)")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Library.continueReadingOpenButton].isHittable)
        XCTAssertFalse(app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].exists,
                       "Closing must restore Reading rather than navigate automatically")
    }

    func testBookDetailCapture_ThreeSuccessivePagesKeepActiveBook() {
        navigateToLibrary()
        openFirstBook()
        let sourceTitle = app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].label
        openCaptureFromBookDetail()
        let activeBook = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Active Book:'")).firstMatch
        XCTAssertTrue(activeBook.waitForExistence(timeout: 5))
        let initialLabel = activeBook.label
        XCTAssertTrue(initialLabel.contains(sourceTitle))

        for _ in 0..<3 {
            triggerCapture()
            XCTAssertTrue(waitForPassagesSheet())
            let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
            XCTAssertTrue(save.waitForExistence(timeout: 10))
            XCTAssertTrue(save.isEnabled)
            save.tap()

            // Reusing the deterministic page fixture deliberately exercises duplicate review.
            let camera = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
            for _ in 0..<12 {
                // Observe the completion control, not hittability of a camera behind
                // a dismissing sheet (iOS 26 AX can throw for that hidden element).
                if app.buttons["capture_view_passages_button"].waitForExistence(timeout: 1) { break }
                let saveAnyway = app.buttons.matching(NSPredicate(format: "label IN %@", ["Save Anyway", "Save Duplicate Anyway"])).firstMatch
                if saveAnyway.waitForExistence(timeout: 2) { saveAnyway.tap() }
            }
            XCTAssertTrue(app.buttons["capture_view_passages_button"].waitForExistence(timeout: 5))
            XCTAssertTrue(camera.waitForExistence(timeout: 5) && camera.isEnabled)
            XCTAssertEqual(activeBook.label, initialLabel)
            XCTAssertTrue(app.buttons["capture_view_passages_button"].exists)
        }

        app.buttons[AccessibilityIdentifiers.Capture.cancelButton].tap()
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.BookDetail.bookTitle].label, sourceTitle)
    }

    // MARK: - Cancel Flow Tests

    func testCancelCapture_ShowsConfirmation() {
        navigateToExtractionReview()

        logger.step(1, "Finding cancel button")
        let cancelButton = app.navigationBars.buttons[AccessibilityIdentifiers.Capture.passagesCancelButton]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Passages should provide Cancel")
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
        logger.step(1, "Opening low-confidence capture")
        navigateToCaptureWithBook()
        triggerCapture()

        logger.step(2, "Low-quality frames stay on the camera with a retake pill, or open Passages without a percentage")
        let retakePill = app.buttons[AccessibilityIdentifiers.Capture.retakePill]
        if retakePill.waitForExistence(timeout: 6) {
            XCTAssertFalse(
                app.staticTexts["48%"].exists,
                "Retake chrome must not show a confidence percentage"
            )
            captureScreenshot(named: "retake_pill", description: "Too blurry retake pill on quiet capture")
            logger.success("Low-quality capture offered an inline retake")
            return
        }

        XCTAssertTrue(waitForPassagesSheet(), "If the frame is usable, Passages should open")
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton].waitForExistence(timeout: 5),
            "Low-confidence mock extraction should still produce an editable passage"
        )
        XCTAssertFalse(
            app.staticTexts["48%"].exists,
            "Passages cards must not show a confidence percentage"
        )
        XCTAssertTrue(revealForInteraction(app.staticTexts["Check carefully"].firstMatch),
                      "Low confidence must have an explicit checking instruction")
        logger.success("Low-confidence extraction has text guidance without a percentage badge")
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
        XCTAssertTrue(waitForPassagesSheet(), "Mock capture should open Passages")
    }

    @discardableResult
    private func waitForPassagesSheet() -> Bool {
        let consent = app.buttons["Allow Remote AI Processing"]
        if consent.waitForExistence(timeout: 3) {
            consent.tap()
        }

        return waitUntil("Passages sheet", timeout: 20) { [weak self] in
            guard let self else { return false }
            if self.app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].exists { return true }
            if self.app.buttons[AccessibilityIdentifiers.Capture.addManualPassage].exists { return true }
            if self.app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton].exists { return true }
            if self.app.navigationBars["Passages"].exists { return true }
            if self.app.staticTexts["Passages"].exists { return true }
            if self.app.staticTexts["No marked passages found"].exists { return true }
            return false
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

    private func triggerCapture() {
        let testButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testButton.waitForExistence(timeout: 5), "Mocked quote capture should provide Use Test Image")
        testButton.tap()
    }

    private func openQuoteCaptureFromTab() {
        openQuoteCaptureFromTabSelectingBook()
    }

    private func openQuoteCaptureFromTabSelectingBook() {
        XCTAssertTrue(openQuietCaptureFromTab(), "Quote capture should show the live camera")
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

        let reviewScrollView = app.scrollViews[AccessibilityIdentifiers.Capture.extractionReviewScrollView]
        let saveButton = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        let addManually = app.buttons[AccessibilityIdentifiers.Capture.addManualPassage]

        XCTAssertTrue(reviewScrollView.waitForExistence(timeout: 5), "Passages should expose a stacked scroll surface")
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Passages should provide Save to Library")
        XCTAssertTrue(addManually.waitForExistence(timeout: 5), "Passages should provide Add a passage manually")
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageSelector)
                .firstMatch.exists,
            "Stacked Passages must not restore the split page selector"
        )
        captureScreenshot(named: "accessibility_text_stacked_review", description: "Compact Passages sheet at accessibility text size")
        openVisibleQuoteEditor()
    }

    func testSourceImageAccessibleActionOpensFullScreen() throws {
        openExtractionReview()

        let source = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", AccessibilityIdentifiers.Capture.viewPageButton)).firstMatch
        XCTAssertTrue(revealForInteraction(source), "Single-page review must offer source inspection")
        source.tap()
        XCTAssertTrue(app.images["Full source page image"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Image Not Found"].exists)
        app.buttons["Close image"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].waitForExistence(timeout: 5))
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

        let reviewScrollView = app.scrollViews[AccessibilityIdentifiers.Capture.extractionReviewScrollView]
        let saveButton = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertTrue(reviewScrollView.waitForExistence(timeout: 5), "Landscape Passages should keep the stacked list")
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Landscape Passages should provide Save to Library")
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageSelector)
                .firstMatch.exists,
            "Landscape Passages must stay a single stacked list"
        )
        captureScreenshot(named: "accessibility_text_landscape_review", description: "Landscape Passages at accessibility text size")
        openVisibleQuoteEditor()
    }

    private func openExtractionReview() {
        XCTAssertTrue(openQuietCaptureFromTab(), "Capture tab should be available")

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Quote capture should show Use Test Image")
        testImageButton.tap()

        XCTAssertTrue(
            app.navigationBars["Passages"].waitForExistence(timeout: 15)
                || app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].waitForExistence(timeout: 2),
            "Mock capture should open Passages"
        )
    }

    private func openVisibleQuoteEditor() {
        let reviewScrollView = app.scrollViews[AccessibilityIdentifiers.Capture.extractionReviewScrollView]
        XCTAssertTrue(reviewScrollView.waitForExistence(timeout: 5), "Compact review should expose its vertical scroll surface")

        for _ in 0..<12 {
            if let editButton = visibleQuoteEditButton() {
                editButton.tap()
                XCTAssertTrue(
                    app.navigationBars["Edit Quote"].waitForExistence(timeout: 5),
                    "Extracted quotes should remain editable"
                )
                return
            }
            // Use the presented sheet's navigation bar, not the underlying
            // Library bar. Reverse if a gesture passed the first edit row.
            let first = app.buttons[AccessibilityIdentifiers.Capture.extractionQuoteEditButton].firstMatch
            let top = app.navigationBars["Passages"].frame.maxY
            let moveDown = first.exists && first.frame.minY < top
            reviewScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1,
                       thenDragTo: reviewScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: moveDown ? 0.6 : 0.4)),
                       withVelocity: .slow,
                       thenHoldForDuration: 0.2)
        }

        XCTFail("A visible edit control should be available after scrolling the extraction review")
    }

    private func visibleQuoteEditButton() -> XCUIElement? {
        let navBar = app.navigationBars["Passages"]
        let topBound = navBar.exists ? navBar.frame.maxY : app.frame.minY
        let editButtons = app.buttons.matching(identifier: AccessibilityIdentifiers.Capture.extractionQuoteEditButton)
        for index in 0..<editButtons.count {
            let editButton = editButtons.element(boundBy: index)
            let frame = editButton.frame
            if frame.height > 0,
               frame.minY >= topBound,
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
        XCTAssertTrue(openQuietCaptureFromTab(), "Capture tab should be available")

        let testImageButton = app.buttons[AccessibilityIdentifiers.Capture.testImageButton]
        XCTAssertTrue(testImageButton.waitForExistence(timeout: 5), "Quote capture should show Use Test Image")
        testImageButton.tap()

        XCTAssertTrue(
            app.navigationBars["Passages"].waitForExistence(timeout: 15)
                || app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton].waitForExistence(timeout: 2),
            "Mock capture should open Passages"
        )

        let reviewScrollView = app.scrollViews[AccessibilityIdentifiers.Capture.extractionReviewScrollView]
        XCTAssertTrue(reviewScrollView.waitForExistence(timeout: 5), "Passages should stay a stacked list at any width")
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Capture.extractionPageSelector)
                .firstMatch.exists,
            "Regular-width Passages must not restore a thumbnail column"
        )
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Capture.addManualPassage].waitForExistence(timeout: 5),
            "Passages should provide Add a passage manually"
        )
        let checking = app.staticTexts["capture_checking_summary"]
        XCTAssertTrue(checking.exists)
        XCTAssertTrue(checking.label.contains("1 of 2 flagged for extra checking"))
        let save = app.buttons[AccessibilityIdentifiers.Capture.saveToLibraryButton]
        XCTAssertEqual(save.label, "Save 2 passages")
        let source = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", AccessibilityIdentifiers.Capture.viewPageButton)).firstMatch
        XCTAssertTrue(revealForInteraction(source))
        source.tap()
        XCTAssertTrue(app.images["Full source page image"].waitForExistence(timeout: 5))
        app.buttons["Close image"].tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        captureScreenshot(named: "ipad_stacked_review", description: "iPad stacked Passages with checking count and working source inspection")
    }
}
