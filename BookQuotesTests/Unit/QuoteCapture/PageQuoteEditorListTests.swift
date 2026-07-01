import XCTest

@testable import BookQuotes

final class PageQuoteEditorListTests: XCTestCase {

    func testCountTitleUsesSingularAndPluralQuoteLabels() {
        XCTAssertEqual(PageQuoteEditorList(quotes: []).countTitle, "0 Quotes")
        XCTAssertEqual(PageQuoteEditorList(quotes: [quote(text: "One")]).countTitle, "1 Quote")
        XCTAssertEqual(PageQuoteEditorList(quotes: [quote(text: "One"), quote(text: "Two")]).countTitle, "2 Quotes")
    }

    func testDeletingQuoteRemovesOnlyMatchingIdentity() {
        let firstId = UUID()
        let secondId = UUID()
        let sameText = "Same extracted text"
        var list = PageQuoteEditorList(quotes: [
            quote(id: firstId, text: sameText),
            quote(id: secondId, text: sameText)
        ])

        list.delete(quote(id: firstId, text: sameText))

        XCTAssertEqual(list.quotes.map(\.id), [secondId])
    }

    private func quote(id: UUID = UUID(), text: String) -> EditableQuote {
        EditableQuote(
            id: id,
            pageId: UUID(),
            text: text,
            markingType: "underline"
        )
    }
}
