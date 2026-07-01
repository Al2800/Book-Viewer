import XCTest

@testable import BookQuotes

final class QuoteSaveDraftTests: XCTestCase {
    func testMakesQuoteFromExtractedQuoteAndSourceImage() throws {
        let book = Book(title: "The Book", author: "The Author")
        let extractedQuote = ExtractedQuote(
            text: "A sufficiently long extracted quote.",
            markingType: .highlight,
            confidence: 0.87,
            pageNumber: 42,
            chapter: "Chapter 3",
            marginNote: "Important idea"
        )
        let sourceImage = Data([1, 2, 3])

        let quote = try QuoteSaveDraft(
            extractedQuote: extractedQuote,
            book: book,
            sourceImage: sourceImage
        )
        .makeQuote()

        XCTAssertEqual(quote.text, "A sufficiently long extracted quote.")
        XCTAssertEqual(quote.book?.id, book.id)
        XCTAssertEqual(quote.markingType, .highlight)
        XCTAssertEqual(quote.confidence, 0.87)
        XCTAssertEqual(quote.pageNumber, 42)
        XCTAssertEqual(quote.chapter, "Chapter 3")
        XCTAssertEqual(quote.marginNote, "Important idea")
        XCTAssertEqual(quote.sourceImageData, sourceImage)
    }
}
