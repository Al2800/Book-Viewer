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

    func testCustomMarkingDefinitionSurvivesReviewAndSave() throws {
        let book = Book(title: "The Book", author: "The Author")
        let customMarking = MarkingDefinition(
            name: "Follow Up",
            visualDescription: "Single underline under text",
            meaning: "Revisit this passage"
        )
        let editableQuote = EditableQuote(
            pageId: UUID(),
            text: "A sufficiently long extracted quote with a custom marking.",
            markingType: "underline",
            customMarkingDefinitionID: customMarking.id,
            customMarkingDisplayName: customMarking.name
        )

        let extractedQuote = editableQuote.toExtractedQuote(
            customMarkingDefinition: customMarking
        )
        let quote = try QuoteSaveDraft(
            extractedQuote: extractedQuote,
            book: book,
            sourceImage: nil
        )
        .makeQuote()

        XCTAssertEqual(quote.customMarkingDefinition?.id, customMarking.id)
        XCTAssertEqual(quote.markingDisplayName, "Follow Up")
    }

    func testSuggestedTagsAndBoundingBoxSurviveReviewAndSave() throws {
        let book = Book(title: "Atomic Habits", author: "James Clear")
        let editableQuote = EditableQuote(
            pageId: UUID(),
            text: "You do not rise to the level of your goals. You fall to the level of your systems.",
            markingType: "underline",
            confidence: 0.96,
            pageNumber: 27,
            marginNote: "Systems over goals",
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.05),
            suggestedTags: ["habits", "systems", "productivity"]
        )

        let extractedQuote = editableQuote.toExtractedQuote()
        let quote = try QuoteSaveDraft(
            extractedQuote: extractedQuote,
            book: book,
            sourceImage: nil
        )
        .makeQuote()

        XCTAssertEqual(quote.boundingBox, CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.05))
        XCTAssertEqual(quote.suggestedTagNames, ["habits", "systems", "productivity"])
        XCTAssertEqual(quote.marginNote, "Systems over goals")
    }
}
