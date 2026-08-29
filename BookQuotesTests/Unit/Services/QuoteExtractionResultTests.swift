import CoreGraphics
import SwiftData
import XCTest

@testable import BookQuotes

final class QuoteExtractionResultTests: XCTestCase {

    func testDecodeExtractedQuoteDataWithBoundingBoxAndTags() throws {
        let json = """
        {
            "quotes": [
                {
                    "text": "The impediment to action advances action.",
                    "pageNumber": 42,
                    "marginNote": "Marcus Aurelius core principle",
                    "markingType": "underline",
                    "confidence": 0.95,
                    "boundingBox": [0.1, 0.2, 0.8, 0.05],
                    "suggestedTags": ["stoicism", "philosophy", "action"]
                }
            ],
            "pageNumber": 42
        }
        """.data(using: .utf8)!

        let result = try QuoteExtractionResult.parse(from: String(data: json, encoding: .utf8)!)
        XCTAssertEqual(result.quotes.count, 1)

        let quoteData = result.quotes[0]
        XCTAssertEqual(quoteData.text, "The impediment to action advances action.")
        XCTAssertEqual(quoteData.pageNumber, 42)
        XCTAssertEqual(quoteData.boundingBox, [0.1, 0.2, 0.8, 0.05])
        XCTAssertEqual(quoteData.suggestedTags, ["stoicism", "philosophy", "action"])

        let expectedRect = CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.05)
        XCTAssertEqual(quoteData.normalizedBoundingBox, expectedRect)

        let extractedQuote = quoteData.toExtractedQuote()
        XCTAssertEqual(extractedQuote.boundingBox, expectedRect)
        XCTAssertEqual(extractedQuote.suggestedTags, ["stoicism", "philosophy", "action"])
    }

    func testQuoteModelBoundingBoxAndSuggestedTagsPersistence() throws {
        let schema = Schema([Book.self, Quote.self, Tag.self, Collection.self, MarkingDefinition.self, PageCapture.self, CaptureSession.self])
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = ModelContext(container)

        let book = Book(title: "Meditations", author: "Marcus Aurelius")
        context.insert(book)

        let extracted = ExtractedQuote(
            text: "What stands in the way becomes the way.",
            markingType: .underline,
            confidence: 0.98,
            pageNumber: 55,
            boundingBox: CGRect(x: 0.15, y: 0.35, width: 0.70, height: 0.08),
            suggestedTags: ["stoicism", "resilience"]
        )

        let draft = QuoteSaveDraft(extractedQuote: extracted, book: book)
        let quote = try draft.makeQuote()
        context.insert(quote)
        try context.save()

        XCTAssertEqual(quote.boundingBoxX, 0.15)
        XCTAssertEqual(quote.boundingBoxY, 0.35)
        XCTAssertEqual(quote.boundingBoxWidth, 0.70)
        XCTAssertEqual(quote.boundingBoxHeight, 0.08)
        XCTAssertEqual(quote.boundingBox, CGRect(x: 0.15, y: 0.35, width: 0.70, height: 0.08))
        XCTAssertEqual(quote.suggestedTagNames, ["stoicism", "resilience"])

        // Test mutating bounding box via computed property
        quote.boundingBox = CGRect(x: 0.2, y: 0.4, width: 0.6, height: 0.1)
        XCTAssertEqual(quote.boundingBoxX, 0.2)
        XCTAssertEqual(quote.boundingBoxY, 0.4)
        XCTAssertEqual(quote.boundingBoxWidth, 0.6)
        XCTAssertEqual(quote.boundingBoxHeight, 0.1)

        quote.boundingBox = nil
        XCTAssertNil(quote.boundingBoxX)
        XCTAssertNil(quote.boundingBoxY)
        XCTAssertNil(quote.boundingBoxWidth)
        XCTAssertNil(quote.boundingBoxHeight)
        XCTAssertNil(quote.boundingBox)
    }

    func testInvalidBoundingBoxesAreSafelyIgnored() throws {
        let json = """
        {
            "quotes": [
                {
                    "text": "A valid quote text.",
                    "markingType": "underline",
                    "boundingBox": [1.5, 0.0, 0.5, 0.5]
                },
                {
                    "text": "Another valid quote text.",
                    "markingType": "highlight",
                    "boundingBox": [0.1, 0.2]
                }
            ]
        }
        """

        let result = try QuoteExtractionResult.parse(from: json)
        XCTAssertEqual(result.quotes.count, 2)
        XCTAssertNil(result.quotes[0].boundingBox)
        XCTAssertNil(result.quotes[0].normalizedBoundingBox)
        XCTAssertNil(result.quotes[1].boundingBox)
        XCTAssertNil(result.quotes[1].normalizedBoundingBox)
    }
}
