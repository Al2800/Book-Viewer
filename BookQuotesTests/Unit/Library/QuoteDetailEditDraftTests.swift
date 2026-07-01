import XCTest

@testable import BookQuotes

final class QuoteDetailEditDraftTests: XCTestCase {

    func testAppliesEditedTextMarginNotePageNumberAndModifiedDate() {
        let quote = Quote(text: "Original quote")
        let modifiedDate = Date(timeIntervalSince1970: 1_234)

        QuoteDetailEditDraft(
            text: "Edited quote",
            marginNote: "Updated note",
            pageNumberText: "42",
            modifiedDate: modifiedDate
        )
        .apply(to: quote)

        XCTAssertEqual(quote.text, "Edited quote")
        XCTAssertEqual(quote.marginNote, "Updated note")
        XCTAssertEqual(quote.pageNumber, 42)
        XCTAssertEqual(quote.dateModified, modifiedDate)
    }

    func testEmptyMarginNoteAndInvalidPageNumberClearExistingValues() {
        let quote = Quote(text: "Original quote")
        quote.marginNote = "Existing note"
        quote.pageNumber = 25

        QuoteDetailEditDraft(
            text: "Edited quote",
            marginNote: "",
            pageNumberText: "not a page",
            modifiedDate: Date(timeIntervalSince1970: 1_235)
        )
        .apply(to: quote)

        XCTAssertNil(quote.marginNote)
        XCTAssertNil(quote.pageNumber)
    }
}
