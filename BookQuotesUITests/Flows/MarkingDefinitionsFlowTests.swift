import XCTest

/// UI tests for the Settings -> Marking Definitions flow.
final class MarkingDefinitionsFlowTests: BaseUITestCase {

    override func waitForAppReady() {
        super.waitForAppReady()
        _ = tapTab(.settings, timeout: 5)
    }

    func testSettingsRoot_DisplaysCoreSectionsAndRows() {
        logger.step(1, "Verifying Settings root title and top sections")
        assertNavigationTitle("Settings", timeout: 5)
        XCTAssertTrue(waitForText("Account", timeout: 3), "Account section should be visible")
        XCTAssertTrue(waitForText("Capture", timeout: 3), "Capture section should be visible")
        XCTAssertTrue(waitForText("Marking Definitions", timeout: 3), "Marking definitions row should be visible")
        XCTAssertTrue(waitForText("Auto-process Queue", timeout: 3), "Auto-process toggle should be visible")

        logger.step(2, "Verifying lower Settings sections by scrolling")
        XCTAssertTrue(findTextByScrolling("Library View"), "Library view setting should be visible")
        XCTAssertTrue(findTextByScrolling("Haptic Feedback"), "Haptic feedback setting should be visible")
        XCTAssertTrue(findTextByScrolling("Export Quotes"), "Export quotes row should be visible")
        XCTAssertTrue(findTextByScrolling("Storage & Export"), "Storage and export row should be visible")
        XCTAssertTrue(findTextByScrolling("About BookQuotes"), "About row should be visible")
        XCTAssertTrue(findElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.privacyPolicyButton]), "Privacy policy row should be visible")
        XCTAssertTrue(findElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.termsOfServiceButton]), "Terms row should be visible")

        logger.success("Settings root sections and rows are visible")
    }

    func testSettingsRoot_NavigatesToExtractedDestinationsAndLegalSheets() {
        logger.step(1, "Opening Account destination")
        XCTAssertTrue(tapSettingsRow(AccessibilityIdentifiers.Settings.accountRow))
        assertNavigationTitle("Account", timeout: 5)
        XCTAssertTrue(
            waitForText("Optional Account", timeout: 3) ||
            waitForText("Sign Out", timeout: 1) ||
            waitForText("Unlock Premium", timeout: 1),
            "Account destination should show account or subscription content"
        )
        tapBackButton()
        assertNavigationTitle("Settings", timeout: 5)

        logger.step(2, "Opening Storage & Export destination")
        XCTAssertTrue(tapSettingsRow(AccessibilityIdentifiers.Settings.storageAndExportRow))
        assertNavigationTitle("Storage & Export", timeout: 5)
        XCTAssertTrue(
            app.buttons["Clear Image Cache"].waitForExistence(timeout: 3),
            "Storage screen should expose cache management"
        )
        tapBackButton()
        assertNavigationTitle("Settings", timeout: 5)

        logger.step(3, "Opening About destination")
        XCTAssertTrue(tapSettingsRow(AccessibilityIdentifiers.Settings.aboutRow))
        assertNavigationTitle("About", timeout: 5)
        XCTAssertTrue(waitForText("BookQuotes", timeout: 3), "About screen should show app name")
        tapBackButton()
        assertNavigationTitle("Settings", timeout: 5)

        logger.step(4, "Verifying legal rows remain visible")
        XCTAssertTrue(findElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.privacyPolicyButton]))
        XCTAssertTrue(findElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.termsOfServiceButton]))

        logger.success("Extracted Settings destinations and legal rows remain reachable")
    }

    func testSettingsRoot_PrivacyPolicySheet_OpensLegalContent() {
        logger.step(1, "Opening Privacy Policy from Settings")
        XCTAssertTrue(tapElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.privacyPolicyButton]))

        logger.step(2, "Verifying Privacy Policy legal content")
        assertNavigationTitle("Privacy Policy", timeout: 5)
        XCTAssertTrue(waitForText("Our Commitment", timeout: 3), "Privacy Policy content should be visible")

        logger.success("Privacy Policy sheet opens from Settings")
    }

    func testSettingsRoot_TermsOfServiceSheet_OpensLegalContent() {
        logger.step(1, "Opening Terms of Service from Settings")
        XCTAssertTrue(tapElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.termsOfServiceButton]))

        logger.step(2, "Verifying Terms of Service legal content")
        assertNavigationTitle("Terms of Service", timeout: 5)
        XCTAssertTrue(waitForText("Agreement", timeout: 3), "Terms of Service content should be visible")

        logger.success("Terms of Service sheet opens from Settings")
    }

    func testSettingsRoot_ExportQuotesSheet_StillOpens() {
        logger.step(1, "Opening Export Quotes from Settings")
        XCTAssertTrue(tapElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.exportQuotesButton]))

        logger.step(2, "Verifying Export Quotes sheet")
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.Export.formatPicker].waitForExistence(timeout: 5) ||
            app.staticTexts["No Quotes"].waitForExistence(timeout: 1),
            "Export sheet should show export controls or the no-quotes empty state"
        )

        logger.success("Export Quotes sheet opens from Settings")
    }

    func testSettings_MarkingDefinitions_AddCustomMarking() {
        logger.step(1, "Opening Marking Definitions from Settings")
        openMarkingDefinitions()

        logger.step(2, "Starting Add Custom Marking")
        let addButton = app.buttons[AccessibilityIdentifiers.MarkingDefinitions.addButton]
        XCTAssertTrue(findButtonByScrolling(addButton), "Add Custom Marking button should exist")
        addButton.tap()

        logger.step(3, "Filling required fields")
        let name = "UITest Marking \(Int(Date().timeIntervalSince1970))"
        let visual = "Wavy or squiggly line under the text"
        let meaning = "I disagree with this statement"

        typeIntoField(identifier: AccessibilityIdentifiers.MarkingEditor.nameField, text: name, dismissKeyboardAfter: false)
        advanceMarkingEditorField()
        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.MarkingEditor.visualDescriptionField].waitForExistence(timeout: 2),
            "Next should focus the visual description field"
        )
        typeIntoField(
            identifier: AccessibilityIdentifiers.MarkingEditor.visualDescriptionField,
            text: visual,
            dismissKeyboardAfter: false
        )
        advanceMarkingEditorField()
        XCTAssertTrue(
            app.textFields[AccessibilityIdentifiers.MarkingEditor.meaningField].waitForExistence(timeout: 2),
            "Next should focus the meaning field"
        )
        typeIntoField(identifier: AccessibilityIdentifiers.MarkingEditor.meaningField, text: meaning)

        logger.step(4, "Saving new marking")
        let saveButton = app.buttons[AccessibilityIdentifiers.MarkingEditor.saveButton]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save should enable after all required fields are completed")
        saveButton.tap()

        logger.step(5, "Verifying new marking appears in list")
        assertNavigationTitle("Marking Styles", timeout: 3)
        XCTAssertTrue(waitForText(name, timeout: 5) || findTextByScrolling(name), "New marking should appear in the list")

        logger.success("Custom marking created and visible")
    }

    // MARK: - Helpers

    private func openMarkingDefinitions() {
        // Settings view is a ScrollView; the row may be off-screen.
        let rowId = AccessibilityIdentifiers.Settings.markingDefinitionsRow

        let element = app.descendants(matching: .any).matching(identifier: rowId).firstMatch
        for _ in 0..<4 {
            if element.exists {
                if element.isHittable {
                    element.tap()
                } else {
                    element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                }
                break
            }
            app.swipeUp()
        }

        // Verify the destination loaded.
        let list = app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.MarkingDefinitions.listView).firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 5), "Marking Definitions list should be visible")
    }

    private func tapSettingsRow(_ identifier: String) -> Bool {
        let row = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        return tapElementByScrolling(row)
    }

    private func advanceMarkingEditorField() {
        let keyboardAction = app.buttons[AccessibilityIdentifiers.MarkingEditor.keyboardActionButton]
        XCTAssertTrue(keyboardAction.waitForExistence(timeout: 2), "Keyboard action should be available")
        keyboardAction.tap()
    }

    private func typeIntoField(identifier: String, text: String, dismissKeyboardAfter: Bool = true) {
        if let textField = findHittableField(identifier: identifier, query: app.textFields) {
            typeText(text, into: textField, timeout: 2, dismissKeyboardAfter: dismissKeyboardAfter)
            return
        }
        if let textView = findHittableField(identifier: identifier, query: app.textViews) {
            typeText(text, into: textView, timeout: 2, dismissKeyboardAfter: dismissKeyboardAfter)
            return
        }
        if let other = findHittableField(identifier: identifier, query: app.otherElements) {
            // Some SwiftUI fields surface as otherElements; attempt typing anyway.
            typeText(text, into: other, timeout: 2, dismissKeyboardAfter: dismissKeyboardAfter)
            return
        }

        XCTFail("Field not found: \(identifier)")
    }

    private func findHittableField(identifier: String, query: XCUIElementQuery) -> XCUIElement? {
        for _ in 0..<8 {
            let element = query[identifier]
            if element.exists && element.isHittable { return element }
            let scrollViews = app.scrollViews
            let scrollViewCount = scrollViews.count
            let scrollView = scrollViewCount > 0 ? scrollViews.element(boundBy: scrollViewCount - 1) : app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        let element = query[identifier]
        return element.exists && element.isHittable ? element : nil
    }

    private func tapKeyboardAdvanceIfPresent() -> Bool {
        if tapKeyboardNextIfPresent() { return true }

        let returnKey = app.keyboards.buttons["Return"]
        if returnKey.exists, returnKey.isHittable {
            returnKey.tap()
            return true
        }

        guard app.keyboards.firstMatch.exists else { return false }
        app.typeText("\n")
        return true
    }

    private func findTextByScrolling(_ text: String) -> Bool {
        for _ in 0..<6 {
            if waitForText(text, timeout: 0.3) { return true }
            app.swipeUp()
        }
        return false
    }

    private func findButtonByScrolling(_ button: XCUIElement) -> Bool {
        for _ in 0..<8 {
            if button.exists && button.isHittable { return true }
            app.swipeUp()
        }
        return button.exists
    }

    private func tapTextByScrolling(_ texts: [String]) -> Bool {
        for _ in 0..<8 {
            for text in texts {
                let button = app.buttons[text].firstMatch
                if button.exists {
                    if button.isHittable {
                        button.tap()
                    } else {
                        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    }
                    return true
                }

                let element = app.staticTexts[text].firstMatch
                if element.exists {
                    if element.isHittable {
                        element.tap()
                    } else {
                        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    }
                    return true
                }
            }
            app.swipeUp()
        }
        return false
    }

    private func tapElementByScrolling(_ element: XCUIElement) -> Bool {
        for _ in 0..<8 {
            if element.exists && element.isHittable {
                element.tap()
                return true
            }
            app.swipeUp()
        }
        return false
    }

    private func findElementByScrolling(_ element: XCUIElement) -> Bool {
        for _ in 0..<8 {
            if element.exists { return true }
            app.swipeUp()
        }
        return element.exists
    }
}

/// Regression coverage for Settings at the largest supported text size.
final class AdaptiveSettingsLayoutTests: BaseUITestCase {

    override var additionalLaunchArguments: [String] {
        [
            "--preload-library-test-data",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
    }

    override func waitForAppReady() {
        super.waitForAppReady()
        XCTAssertTrue(tapTab(.settings), "Settings tab should be available")
    }

    func testSettingsActionsRemainReachableWithAccessibilityText() {
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.Settings.remoteAIProcessingRow),
            "Remote AI Processing should remain reachable at accessibility text sizes"
        )
        captureScreenshot(named: "accessibility_text_settings", description: "Settings at accessibility text size")

        let remoteProcessing = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Settings.remoteAIProcessingRow)
            .firstMatch
        remoteProcessing.tap()

        XCTAssertTrue(
            app.navigationBars["AI Processing"].waitForExistence(timeout: 5),
            "Remote AI Processing should still open"
        )
        let remoteToggle = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Settings.remoteAIProcessingToggle)
            .firstMatch
        XCTAssertTrue(remoteToggle.waitForExistence(timeout: 5), "Remote processing toggle should exist")
        XCTAssertTrue(remoteToggle.isHittable, "Remote processing toggle should remain reachable")

        tapBackButton()
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.Settings.storageAndExportRow),
            "Storage and export should remain reachable after returning to Settings"
        )

        let storage = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Settings.storageAndExportRow)
            .firstMatch
        storage.tap()
        XCTAssertTrue(
            app.navigationBars["Storage & Export"].waitForExistence(timeout: 5),
            "Storage and export should still open"
        )
    }

    func testExportWorkflowRemainsReachableWithAccessibilityText() {
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.Settings.exportQuotesButton),
            "Export Quotes should remain reachable at accessibility text sizes"
        )
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Settings.exportQuotesButton)
            .firstMatch
            .tap()

        let formatPicker = app.buttons[AccessibilityIdentifiers.Export.formatPicker]
        XCTAssertTrue(formatPicker.waitForExistence(timeout: 5), "The export format picker should be available")
        XCTAssertTrue(formatPicker.isHittable, "The export format picker should remain reachable")
        formatPicker.tap()
        let jsonOption = app.buttons["JSON"]
        XCTAssertTrue(jsonOption.waitForExistence(timeout: 3), "JSON should remain available as an export format")
        jsonOption.tap()

        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.Export.includeMarginNotesToggle),
            "All export options should remain reachable"
        )
        let marginNotes = app.switches[AccessibilityIdentifiers.Export.includeMarginNotesToggle]
        XCTAssertTrue(marginNotes.exists && marginNotes.isHittable, "Include margin notes should be usable")

        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.Export.previewText),
            "The export preview should remain reachable"
        )
        let preview = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Export.previewText)
            .firstMatch
        XCTAssertTrue(preview.label.contains("{"), "The JSON preview should reflect the selected format")
        captureScreenshot(
            named: "accessibility_text_export",
            description: "Export options and preview at accessibility text size"
        )

        let exportButton = app.buttons[AccessibilityIdentifiers.Export.exportButton]
        XCTAssertTrue(exportButton.exists && exportButton.isHittable, "The final Export action should remain reachable")
        exportButton.tap()
        XCTAssertTrue(app.buttons["Save to Files"].waitForExistence(timeout: 5), "Save to Files should be offered")
        XCTAssertTrue(app.buttons["Share"].exists, "Share should be offered")
        app.swipeDown()
    }

    func testMarkingEditorFieldsRemainReachableWithAccessibilityText() {
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.Settings.markingDefinitionsRow),
            "Marking Definitions should remain reachable at accessibility text sizes"
        )
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Settings.markingDefinitionsRow)
            .firstMatch
            .tap()

        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.MarkingDefinitions.listView)
                .firstMatch
                .waitForExistence(timeout: 5),
            "Marking Styles should open"
        )
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.MarkingDefinitions.addButton),
            "Add Custom Marking should remain reachable"
        )
        captureScreenshot(
            named: "accessibility_text_marking_definitions",
            description: "Marking definitions at accessibility text size"
        )
        app.buttons[AccessibilityIdentifiers.MarkingDefinitions.addButton].tap()

        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.MarkingEditor.nameField),
            "The marking name field should remain reachable"
        )
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.MarkingEditor.visualDescriptionField),
            "The visual description field should remain reachable"
        )
        XCTAssertTrue(
            scrollToHittable(AccessibilityIdentifiers.MarkingEditor.meaningField),
            "The meaning field should remain reachable"
        )
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.MarkingEditor.cancelButton].exists,
            "The editor should keep its Cancel action visible"
        )
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifiers.MarkingEditor.saveButton].exists,
            "The editor should keep its Save action visible"
        )
        captureScreenshot(
            named: "accessibility_text_marking_editor",
            description: "Marking editor fields at accessibility text size"
        )
    }

    private func scrollToHittable(_ identifier: String) -> Bool {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        for _ in 0..<8 {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}
