import XCTest
import SwiftUI

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

    func testConfidenceBarColorUsesThreeThresholds() {
        XCTAssertEqual(QuoteEditRow.confidenceBarColor(for: 0.8), Color.success)
        XCTAssertEqual(QuoteEditRow.confidenceBarColor(for: 0.95), Color.success)
        XCTAssertEqual(QuoteEditRow.confidenceBarColor(for: 0.5), Color.warning)
        XCTAssertEqual(QuoteEditRow.confidenceBarColor(for: 0.79), Color.warning)
        XCTAssertEqual(QuoteEditRow.confidenceBarColor(for: 0.49), Color.error)
        XCTAssertEqual(QuoteEditRow.confidenceBarColor(for: nil), Color.error)
    }

    func testPassagesPageHeadersUseCaptureOrder() {
        XCTAssertEqual(ExtractionReviewPageHeader.title(orderIndex: 0), "PAGE 1")
        XCTAssertEqual(ExtractionReviewPageHeader.title(orderIndex: 1), "PAGE 2")
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
