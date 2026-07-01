import XCTest

@testable import BookQuotes

final class QuoteDetailEditFieldsTests: XCTestCase {
    func testLoadsExistingQuoteFieldsForEditing() {
        let quote = Quote(text: "Original quote")
        quote.marginNote = "Existing note"
        quote.pageNumber = 42

        let fields = QuoteDetailEditFields(quote: quote)

        XCTAssertEqual(fields.text, "Original quote")
        XCTAssertEqual(fields.marginNote, "Existing note")
        XCTAssertEqual(fields.pageNumberText, "42")
    }

    func testUsesEmptyStringsForMissingOptionalFields() {
        let quote = Quote(text: "Original quote")

        let fields = QuoteDetailEditFields(quote: quote)

        XCTAssertEqual(fields.text, "Original quote")
        XCTAssertEqual(fields.marginNote, "")
        XCTAssertEqual(fields.pageNumberText, "")
    }
}
