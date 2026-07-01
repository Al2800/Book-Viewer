import XCTest

@testable import BookQuotes

final class TagEditorModePresentationTests: XCTestCase {
    func testCreateModeUsesNewTagTitleAndCreateAction() {
        let presentation = TagEditorModePresentation(mode: .create)

        XCTAssertTrue(presentation.mode.isCreateMode)
        XCTAssertEqual(presentation.navigationTitle, "New Tag")
        XCTAssertEqual(presentation.confirmationActionTitle, "Create")
    }

    func testEditModeUsesEditTitleAndSaveAction() {
        let presentation = TagEditorModePresentation(mode: .edit(Tag(name: "strategy")))

        XCTAssertFalse(presentation.mode.isCreateMode)
        XCTAssertEqual(presentation.navigationTitle, "Edit Tag")
        XCTAssertEqual(presentation.confirmationActionTitle, "Save")
    }
}
