import XCTest

@testable import BookQuotes

final class TagEditorDraftTests: XCTestCase {
    func testNormalizesNameForSave() {
        let draft = TagEditorDraft(name: "  Strategy  ", colorName: "green")

        XCTAssertEqual(draft.normalizedName, "strategy")
        XCTAssertTrue(draft.canSave)
    }

    func testCannotSaveBlankNames() {
        let draft = TagEditorDraft(name: "   ", colorName: "blue")

        XCTAssertFalse(draft.canSave)
        XCTAssertEqual(draft.normalizedName, "")
    }

    func testMakesTagFromNormalizedFields() {
        let draft = TagEditorDraft(name: "  Craft  ", colorName: "purple")

        let tag = draft.makeTag()

        XCTAssertEqual(tag.name, "craft")
        XCTAssertEqual(tag.colorName, "purple")
    }

    func testAppliesNormalizedFieldsToExistingTag() {
        let tag = Tag(name: "old", colorName: "blue")
        let draft = TagEditorDraft(name: "  Systems  ", colorName: "orange")

        draft.apply(to: tag)

        XCTAssertEqual(tag.name, "systems")
        XCTAssertEqual(tag.colorName, "orange")
    }
}
