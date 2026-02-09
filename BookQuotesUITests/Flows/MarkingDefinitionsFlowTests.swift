import XCTest

/// UI tests for the Settings -> Marking Definitions flow.
final class MarkingDefinitionsFlowTests: BaseUITestCase {

    override func waitForAppReady() {
        super.waitForAppReady()
        _ = tapTab(.settings, timeout: 5)
    }

    func testSettings_MarkingDefinitions_AddCustomMarking() {
        logger.step(1, "Opening Marking Definitions from Settings")
        openMarkingDefinitions()

        logger.step(2, "Starting Add Custom Marking")
        let addButton = app.buttons[AccessibilityIdentifiers.MarkingDefinitions.addButton]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add Custom Marking button should exist")
        addButton.tap()

        logger.step(3, "Filling required fields")
        let name = "UITest Wavy Underline"
        let visual = "Wavy or squiggly line under the text"
        let meaning = "I disagree with this statement"

        typeIntoField(identifier: AccessibilityIdentifiers.MarkingEditor.nameField, text: name)
        typeIntoField(identifier: AccessibilityIdentifiers.MarkingEditor.visualDescriptionField, text: visual)
        typeIntoField(identifier: AccessibilityIdentifiers.MarkingEditor.meaningField, text: meaning)

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

    private func typeIntoField(identifier: String, text: String) {
        let textField = app.textFields[identifier]
        let textView = app.textViews[identifier]
        let other = app.otherElements[identifier]

        if textField.exists || textField.waitForExistence(timeout: 2) {
            typeText(text, into: textField, timeout: 2)
            return
        }
        if textView.exists || textView.waitForExistence(timeout: 2) {
            typeText(text, into: textView, timeout: 2)
            return
        }
        if other.exists || other.waitForExistence(timeout: 2) {
            // Some SwiftUI fields surface as otherElements; attempt typing anyway.
            typeText(text, into: other, timeout: 2)
            return
        }

        XCTFail("Field not found: \(identifier)")
    }

    private func findTextByScrolling(_ text: String) -> Bool {
        for _ in 0..<6 {
            if waitForText(text, timeout: 0.3) { return true }
            app.swipeUp()
        }
        return false
    }
}
