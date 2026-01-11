import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - QuoteModelTests

/// Comprehensive unit tests for Quote SwiftData model.
@MainActor
final class QuoteModelTests: SwiftDataTestCase {

    // MARK: - Creation Tests

    func testQuoteCreation_WithRequiredFields_Succeeds() async throws {
        logger.step(1, "Creating quote with text only")
        let quote = Quote(text: "Test quote text")

        logger.step(2, "Verifying default values")
        XCTAssertNotNil(quote.id)
        XCTAssertEqual(quote.text, "Test quote text")
        XCTAssertEqual(quote.markingType, .underline)
        XCTAssertFalse(quote.isFavorite)
        XCTAssertNotNil(quote.captureDate)
        XCTAssertNotNil(quote.dateModified)
        XCTAssertNil(quote.pageNumber)
        XCTAssertNil(quote.marginNote)
        XCTAssertNil(quote.chapter)
        XCTAssertNil(quote.confidence)
        XCTAssertNil(quote.book)

        logger.success("Quote creation with defaults works")
    }

    func testQuoteCreation_WithAllFields_Succeeds() async throws {
        let book = TestFixtures.book()
        try insertBook(book)

        let quote = TestFixtures.quote { q in
            q.text = "Full quote text"
            q.pageNumber = 42
            q.marginNote = "Great insight"
            q.markingType = .highlight
            q.confidence = 0.95
            q.isFavorite = true
            q.book = book
        }

        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, "Full quote text")
        XCTAssertEqual(fetched.pageNumber, 42)
        XCTAssertEqual(fetched.marginNote, "Great insight")
        XCTAssertEqual(fetched.markingType, .highlight)
        XCTAssertEqual(fetched.confidence, 0.95)
        XCTAssertTrue(fetched.isFavorite)
        XCTAssertEqual(fetched.book?.id, book.id)

        logger.success("All quote fields persist correctly")
    }

    // MARK: - Confidence Tests

    func testQuoteConfidence_EdgeValues() async throws {
        logger.step(1, "Testing confidence = 0.0")
        let lowQuote = TestFixtures.quote { q in q.confidence = 0.0 }
        modelContext.insert(lowQuote)

        logger.step(2, "Testing confidence = 1.0")
        let highQuote = TestFixtures.quote { q in q.confidence = 1.0 }
        modelContext.insert(highQuote)

        logger.step(3, "Testing confidence = nil")
        let noConfidence = TestFixtures.quote { q in q.confidence = nil }
        modelContext.insert(noConfidence)

        try modelContext.save()

        let quotes = try fetchAllQuotes()
        XCTAssertEqual(quotes.count, 3)

        // Verify each confidence value
        let confidences = quotes.map { $0.confidence }
        XCTAssertTrue(confidences.contains(0.0))
        XCTAssertTrue(confidences.contains(1.0))
        XCTAssertTrue(confidences.contains(nil))

        logger.success("Confidence edge values handled correctly")
    }

    func testQuoteConfidence_MidRangeValues() async throws {
        let confidenceValues = [0.25, 0.5, 0.75, 0.85, 0.92]

        for confidence in confidenceValues {
            let quote = TestFixtures.quote { q in q.confidence = confidence }
            modelContext.insert(quote)
        }
        try modelContext.save()

        let quotes = try fetchAllQuotes()
        XCTAssertEqual(quotes.count, confidenceValues.count)

        for value in confidenceValues {
            XCTAssertTrue(
                quotes.contains { $0.confidence == value },
                "Missing confidence value: \(value)"
            )
        }

        logger.success("Mid-range confidence values persist correctly")
    }

    // MARK: - Marking Type Tests

    func testQuoteMarkingType_AllTypesValid() async throws {
        for markingType in MarkingType.allCases {
            logger.debug("Testing marking type: \(markingType.rawValue)")
            let quote = TestFixtures.quote { q in q.markingType = markingType }
            modelContext.insert(quote)
        }

        try modelContext.save()
        let quotes = try fetchAllQuotes()

        XCTAssertEqual(quotes.count, MarkingType.allCases.count)

        for markingType in MarkingType.allCases {
            XCTAssertTrue(
                quotes.contains { $0.markingType == markingType },
                "Missing marking type: \(markingType.rawValue)"
            )
        }

        logger.success("All marking types persist correctly")
    }

    func testQuoteMarkingType_DefaultIsUnderline() async throws {
        let quote = Quote(text: "Test")
        XCTAssertEqual(quote.markingType, .underline)
        logger.success("Default marking type is underline")
    }

    // MARK: - Text Edge Cases

    func testQuoteText_LongText_Persists() async throws {
        let longText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 100)
        logger.info("Testing with text length: \(longText.count)")

        let quote = TestFixtures.quote { q in q.text = longText }
        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, longText)
        XCTAssertEqual(fetched.text.count, longText.count)

        logger.success("Long text persists correctly")
    }

    func testQuoteText_UnicodeCharacters_Persists() async throws {
        let unicodeText = "Japanese: \u{65E5}\u{672C}\u{8A9E} Emojis: \u{1F389}\u{1F4DA} Accents: \u{00E9}\u{00F1}\u{00FC}\u{00DF}"

        let quote = TestFixtures.quote { q in q.text = unicodeText }
        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, unicodeText)

        logger.success("Unicode text persists correctly")
    }

    func testQuoteText_EmptyString_Persists() async throws {
        // While not ideal, empty text should still persist
        let quote = Quote(text: "")
        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, "")

        logger.success("Empty text persists (though not recommended)")
    }

    func testQuoteText_WhitespaceOnly_Persists() async throws {
        let whitespaceText = "   \n\t   "
        let quote = Quote(text: whitespaceText)
        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, whitespaceText)

        logger.success("Whitespace-only text persists")
    }

    func testQuoteText_SpecialCharacters_Persists() async throws {
        let specialText = "\"Quotes\" 'apostrophes' & ampersands < > / \\ | @ # $ % ^ * ( ) [ ] { }"

        let quote = TestFixtures.quote { q in q.text = specialText }
        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, specialText)

        logger.success("Special characters persist correctly")
    }

    // MARK: - Favorite Toggle

    func testQuoteFavorite_Toggle_Persists() async throws {
        let quote = TestFixtures.quote { q in q.isFavorite = false }
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(1, "Initial state: not favorite")
        XCTAssertFalse(quote.isFavorite)

        logger.step(2, "Toggle to favorite")
        quote.isFavorite = true
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertTrue(fetched.isFavorite)

        logger.step(3, "Toggle back to not favorite")
        fetched.isFavorite = false
        try modelContext.save()

        XCTAssertFalse(fetched.isFavorite)

        logger.success("Favorite toggle persists")
    }

    func testQuoteFavorite_DefaultIsFalse() async throws {
        let quote = Quote(text: "Test")
        XCTAssertFalse(quote.isFavorite)
        logger.success("Default favorite is false")
    }

    // MARK: - Page Number Tests

    func testQuotePageNumber_ValidValues() async throws {
        let pageNumbers = [1, 42, 100, 500, 1000]

        for page in pageNumbers {
            let quote = TestFixtures.quote { q in q.pageNumber = page }
            modelContext.insert(quote)
        }
        try modelContext.save()

        let quotes = try fetchAllQuotes()
        XCTAssertEqual(quotes.count, pageNumbers.count)

        for page in pageNumbers {
            XCTAssertTrue(
                quotes.contains { $0.pageNumber == page },
                "Missing page number: \(page)"
            )
        }

        logger.success("Page numbers persist correctly")
    }

    func testQuotePageNumber_NilByDefault() async throws {
        let quote = Quote(text: "Test")
        XCTAssertNil(quote.pageNumber)
        logger.success("Page number nil by default")
    }

    // MARK: - Margin Note Tests

    func testQuoteMarginNote_Persists() async throws {
        let note = "This is a user's margin note about the quote"
        let quote = TestFixtures.quote { q in q.marginNote = note }

        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.marginNote, note)

        logger.success("Margin note persists correctly")
    }

    func testQuoteMarginNote_LongText() async throws {
        let longNote = String(repeating: "Important note. ", count: 50)
        let quote = TestFixtures.quote { q in q.marginNote = longNote }

        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.marginNote, longNote)

        logger.success("Long margin note persists correctly")
    }

    // MARK: - Source Image Tests

    func testQuoteSourceImage_Persists() async throws {
        let imageData = TestFixtures.TestImages.bookPage
        let quote = Quote(text: "Test quote")
        quote.sourceImageData = imageData

        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertNotNil(fetched.sourceImageData)
        XCTAssertEqual(fetched.sourceImageData?.count, imageData.count)

        logger.success("Source image persists correctly")
    }

    func testQuoteSourceImage_NilByDefault() async throws {
        let quote = Quote(text: "Test")
        XCTAssertNil(quote.sourceImageData)
        logger.success("Source image nil by default")
    }

    // MARK: - Date Tests

    func testQuoteDates_SetOnCreation() async throws {
        let before = Date()
        let quote = Quote(text: "Test")
        let after = Date()

        XCTAssertGreaterThanOrEqual(quote.captureDate, before)
        XCTAssertLessThanOrEqual(quote.captureDate, after)
        XCTAssertGreaterThanOrEqual(quote.dateModified, before)
        XCTAssertLessThanOrEqual(quote.dateModified, after)

        logger.success("Dates set correctly on creation")
    }

    // MARK: - Book Relationship Tests

    func testQuote_BookRelationship_BothDirections() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in q.book = book }

        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        // Quote -> Book
        XCTAssertEqual(quote.book?.id, book.id)

        // Book -> Quote
        XCTAssertTrue(book.quotes.contains { $0.id == quote.id })

        logger.success("Bidirectional relationship works")
    }

    func testQuote_WithoutBook_Persists() async throws {
        let quote = Quote(text: "Orphan quote")
        modelContext.insert(quote)
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertNil(fetched.book)

        logger.success("Quote without book persists")
    }

    // MARK: - UUID Uniqueness Tests

    func testQuote_HasUniqueID() async throws {
        let quote1 = Quote(text: "Quote 1")
        let quote2 = Quote(text: "Quote 2")

        XCTAssertNotEqual(quote1.id, quote2.id)

        logger.success("Each quote has unique ID")
    }

    // MARK: - Update Tests

    func testQuote_UpdateText_Persists() async throws {
        let quote = TestFixtures.quote { q in q.text = "Original text" }
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(1, "Updating text")
        quote.text = "Updated text"
        quote.dateModified = Date()
        try modelContext.save()

        logger.step(2, "Verifying update persisted")
        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.text, "Updated text")

        logger.success("Text update persists correctly")
    }

    func testQuote_UpdateMarkingType_Persists() async throws {
        let quote = TestFixtures.quote { q in q.markingType = .underline }
        modelContext.insert(quote)
        try modelContext.save()

        quote.markingType = .highlight
        try modelContext.save()

        let fetched = try XCTUnwrap(fetchAllQuotes().first)
        XCTAssertEqual(fetched.markingType, .highlight)

        logger.success("Marking type update persists correctly")
    }

    // MARK: - Deletion Tests

    func testQuote_Deletion_RemovesFromContext() async throws {
        let quote = TestFixtures.quote()
        modelContext.insert(quote)
        try modelContext.save()

        try assertQuoteCount(1)

        modelContext.delete(quote)
        try modelContext.save()

        try assertQuoteCount(0)

        logger.success("Quote deletion works correctly")
    }

    func testQuote_Deletion_DoesNotDeleteBook() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in q.book = book }

        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        // Delete quote
        modelContext.delete(quote)
        try modelContext.save()

        // Book should still exist
        try assertBookCount(1)
        try assertQuoteCount(0)

        logger.success("Deleting quote doesn't delete book")
    }
}
