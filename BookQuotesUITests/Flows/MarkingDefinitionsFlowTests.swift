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
        XCTAssertTrue(findTextByScrolling("Storage & Backup"), "Storage and backup row should be visible")
        XCTAssertTrue(findTextByScrolling("About BookQuotes"), "About row should be visible")
        XCTAssertTrue(findElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.privacyPolicyButton]), "Privacy policy row should be visible")
        XCTAssertTrue(findElementByScrolling(app.buttons[AccessibilityIdentifiers.Settings.termsOfServiceButton]), "Terms row should be visible")

        logger.success("Settings root sections and rows are visible")
    }

    func testSettingsRoot_NavigatesToExtractedDestinationsAndLegalSheets() {
        logger.step(1, "Opening Account destination")
        XCTAssertTrue(tapTextByScrolling(["Account & Subscription", "Manage sign-in and account access"]))
        assertNavigationTitle("Account", timeout: 5)
        XCTAssertTrue(
            waitForText("Sign In Required", timeout: 3) ||
            waitForText("Sign Out", timeout: 1) ||
            waitForText("Unlock Premium", timeout: 1),
            "Account destination should show account or subscription content"
        )
        tapBackButton()
        assertNavigationTitle("Settings", timeout: 5)

        logger.step(2, "Opening Storage & Backup destination")
        XCTAssertTrue(tapTextByScrolling(["Storage & Backup"]))
        assertNavigationTitle("Storage & Backup", timeout: 5)
        XCTAssertTrue(waitForText("Storage Usage", timeout: 3), "Storage screen should show storage usage")
        tapBackButton()
        assertNavigationTitle("Settings", timeout: 5)

        logger.step(3, "Opening About destination")
        XCTAssertTrue(tapTextByScrolling(["About BookQuotes"]))
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
        let name = "UITest Wavy \(Int(Date().timeIntervalSince1970))"
        let visual = "Wavy or squiggly line under the text"
        let meaning = "I disagree with this statement"

        typeIntoField(identifier: AccessibilityIdentifiers.MarkingEditor.nameField, text: name, dismissKeyboardAfter: false)
        XCTAssertTrue(tapKeyboardAdvanceIfPresent(), "Keyboard should advance from name to visual description")
        typeTextIntoFocusedField(visual, timeout: 2, dismissKeyboardAfter: false)
        XCTAssertTrue(tapKeyboardAdvanceIfPresent(), "Keyboard should advance from visual description to meaning")
        typeTextIntoFocusedField(meaning, timeout: 2)

        logger.step(4, "Saving new marking")
        let saveButton = app.buttons[AccessibilityIdentifiers.MarkingEditor.saveButton]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        // If it's not hittable due to disabled state, the taps below will fail; the field typing above
        // should enable it.
        if saveButton.isHittable {
            saveButton.tap()
        } else {
            saveButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

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
