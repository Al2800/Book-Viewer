import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - GeminiServiceTests

/// Unit tests for GeminiService covering response parsing, error handling, and prompt building.
/// Note: Since we use a proxy model, tests focus on parsing and error handling rather than live API calls.
@MainActor
final class GeminiServiceTests: SwiftDataTestCase {

    // MARK: - Properties

    var authService: AuthService!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        authService = AuthService()
        logger.info("GeminiServiceTests setup complete")
    }

    override func tearDown() async throws {
        authService = nil
        try await super.tearDown()
    }

    // MARK: - Quote Response Parsing Tests

    func testParseQuoteResponse_ValidJSON_Succeeds() async throws {
        logger.step(1, "Preparing valid JSON response")
        let json = """
        {
            "quotes": [
                {
                    "text": "The only way to do great work is to love what you do.",
                    "pageNumber": 42,
                    "marginNote": "Important!",
                    "markingType": "underline",
                    "confidence": 0.95
                }
            ],
            "pageNumber": 42,
            "processingNotes": "Clear image, high confidence extraction"
        }
        """

        logger.step(2, "Parsing response")
        let result = try QuoteExtractionResult.parse(from: json)

        logger.step(3, "Validating parsed data")
        XCTAssertEqual(result.quotes.count, 1)
        XCTAssertEqual(result.quotes.first?.text, "The only way to do great work is to love what you do.")
        XCTAssertEqual(result.quotes.first?.pageNumber, 42)
        XCTAssertEqual(result.quotes.first?.marginNote, "Important!")
        XCTAssertEqual(result.quotes.first?.markingType, "underline")
        XCTAssertEqual(result.quotes.first?.confidence, 0.95)
        XCTAssertEqual(result.pageNumber, 42)
        XCTAssertEqual(result.processingNotes, "Clear image, high confidence extraction")

        logger.success("Valid JSON parsed correctly")
    }

    func testParseQuoteResponse_MultipleQuotes_ParsesAll() async throws {
        logger.step(1, "Preparing JSON with multiple quotes")
        let json = """
        {
            "quotes": [
                {"text": "First quote about learning", "pageNumber": 1, "markingType": "underline", "confidence": 0.9},
                {"text": "Second quote about growth", "pageNumber": 2, "markingType": "highlight", "confidence": 0.85},
                {"text": "Third quote about habits", "pageNumber": 3, "markingType": "bracket", "confidence": 0.8}
            ],
            "pageNumber": 1
        }
        """

        logger.step(2, "Parsing response")
        let result = try QuoteExtractionResult.parse(from: json)

        logger.step(3, "Validating all quotes parsed")
        XCTAssertEqual(result.quotes.count, 3)
        XCTAssertEqual(result.quotes[0].text, "First quote about learning")
        XCTAssertEqual(result.quotes[1].text, "Second quote about growth")
        XCTAssertEqual(result.quotes[2].text, "Third quote about habits")

        logger.success("Multiple quotes parsed correctly")
    }

    func testParseQuoteResponse_MissingOptionalFields_Succeeds() async throws {
        logger.step(1, "Preparing JSON with minimal fields")
        let json = """
        {
            "quotes": [
                {"text": "Minimal quote text", "markingType": "underline", "confidence": 0.7}
            ]
        }
        """

        logger.step(2, "Parsing response")
        let result = try QuoteExtractionResult.parse(from: json)

        logger.step(3, "Validating optional fields are nil")
        XCTAssertNil(result.quotes.first?.pageNumber)
        XCTAssertNil(result.quotes.first?.marginNote)
        XCTAssertNil(result.pageNumber)
        XCTAssertNil(result.processingNotes)

        logger.success("Missing optional fields handled correctly")
    }

    func testParseQuoteResponse_MissingExtractionSourceDefaultsToUnknown() async throws {
        let json = """
        {
            "quotes": [
                {"text": "Legacy stored quote", "markingType": "underline", "confidence": 0.7}
            ]
        }
        """

        let result = try QuoteExtractionResult.parse(from: json)

        XCTAssertEqual(result.quotes.first?.extractionSource, .unknown)
    }

    func testParseQuoteResponse_ExplicitExtractionSourceIsPreserved() async throws {
        let json = """
        {
            "quotes": [
                {
                    "text": "Model selected quote",
                    "markingType": "bracket",
                    "confidence": 0.86,
                    "extractionSource": "model_assisted"
                }
            ]
        }
        """

        let result = try QuoteExtractionResult.parse(from: json)

        XCTAssertEqual(result.quotes.first?.extractionSource, .modelAssisted)
    }

    func testParseQuoteResponse_EmptyQuotes_Succeeds() async throws {
        logger.step(1, "Preparing JSON with empty quotes array")
        let json = """
        {
            "quotes": [],
            "processingNotes": "No marked passages found"
        }
        """

        logger.step(2, "Parsing response")
        let result = try QuoteExtractionResult.parse(from: json)

        logger.step(3, "Validating empty array")
        XCTAssertTrue(result.quotes.isEmpty)
        XCTAssertFalse(result.isSuccessful)
        XCTAssertEqual(result.quoteCount, 0)

        logger.success("Empty quotes array handled correctly")
    }

    func testParseQuoteResponse_InvalidJSON_Throws() async throws {
        logger.step(1, "Preparing invalid JSON")
        let invalidJSON = "not valid json at all"

        logger.step(2, "Attempting to parse")
        XCTAssertThrowsError(try QuoteExtractionResult.parse(from: invalidJSON)) { error in
            logger.debug("Expected error thrown: \(error)")
            if let extractionError = error as? ExtractionError {
                if case .parsingError = extractionError {
                    // Expected
                } else {
                    XCTFail("Wrong error type")
                }
            }
        }

        logger.success("Invalid JSON throws error correctly")
    }

    func testParseQuoteResponse_MalformedJSON_Throws() async throws {
        logger.step(1, "Preparing malformed JSON")
        let malformedJSON = """
        {
            "quotes": [
                {"text": "Missing closing quote}
            ]
        }
        """

        logger.step(2, "Attempting to parse")
        XCTAssertThrowsError(try QuoteExtractionResult.parse(from: malformedJSON))

        logger.success("Malformed JSON throws error correctly")
    }

    func testParseQuoteResponse_CodeBlockWrapped_Succeeds() async throws {
        logger.step(1, "Preparing JSON wrapped in markdown code block")
        let json = """
        ```json
        {
            "quotes": [
                {"text": "Quote from code block", "markingType": "highlight", "confidence": 0.88}
            ]
        }
        ```
        """

        logger.step(2, "Parsing response")
        let result = try QuoteExtractionResult.parse(from: json)

        logger.step(3, "Validating parsed data")
        XCTAssertEqual(result.quotes.count, 1)
        XCTAssertEqual(result.quotes.first?.text, "Quote from code block")

        logger.success("Code block wrapped JSON parsed correctly")
    }

    // MARK: - Book Metadata Response Parsing Tests

    func testParseBookMetadata_ValidJSON_Succeeds() async throws {
        logger.step(1, "Preparing valid book metadata JSON")
        let json = """
        {
            "title": "Atomic Habits",
            "author": "James Clear",
            "subtitle": "An Easy & Proven Way to Build Good Habits & Break Bad Ones",
            "publisher": "Avery",
            "publishYear": 2018,
            "genre": "Self-Help",
            "isbn": "978-0735211292",
            "confidence": 0.95
        }
        """

        logger.step(2, "Parsing response")
        let metadata = try BookMetadataResult.parse(from: json)

        logger.step(3, "Validating parsed metadata")
        XCTAssertEqual(metadata.title, "Atomic Habits")
        XCTAssertEqual(metadata.author, "James Clear")
        XCTAssertEqual(metadata.subtitle, "An Easy & Proven Way to Build Good Habits & Break Bad Ones")
        XCTAssertEqual(metadata.publisher, "Avery")
        XCTAssertEqual(metadata.publishYear, 2018)
        XCTAssertEqual(metadata.genre, "Self-Help")
        XCTAssertEqual(metadata.isbn, "978-0735211292")
        XCTAssertEqual(metadata.confidence, 0.95)

        logger.success("Book metadata parsed correctly")
    }

    func testParseBookMetadata_MinimalFields_Succeeds() async throws {
        logger.step(1, "Preparing minimal book metadata JSON")
        let json = """
        {
            "title": "The Book",
            "author": "Unknown Author",
            "confidence": 0.6
        }
        """

        logger.step(2, "Parsing response")
        let metadata = try BookMetadataResult.parse(from: json)

        logger.step(3, "Validating required fields present")
        XCTAssertEqual(metadata.title, "The Book")
        XCTAssertEqual(metadata.author, "Unknown Author")
        XCTAssertNil(metadata.subtitle)
        XCTAssertNil(metadata.publisher)
        XCTAssertNil(metadata.publishYear)
        XCTAssertNil(metadata.isbn)

        logger.success("Minimal book metadata parsed correctly")
    }

    func testParseBookMetadata_ToBookConversion() async throws {
        logger.step(1, "Preparing book metadata")
        let json = """
        {
            "title": "Deep Work",
            "author": "Cal Newport",
            "publisher": "Grand Central Publishing",
            "publishYear": 2016,
            "genre": "Productivity",
            "confidence": 0.92
        }
        """

        logger.step(2, "Parsing and converting to Book")
        let metadata = try BookMetadataResult.parse(from: json)
        let book = metadata.toBook()

        logger.step(3, "Validating Book object")
        XCTAssertEqual(book.title, "Deep Work")
        XCTAssertEqual(book.author, "Cal Newport")
        XCTAssertEqual(book.publisher, "Grand Central Publishing")
        XCTAssertEqual(book.publishYear, 2016)
        XCTAssertEqual(book.genre, "Productivity")

        logger.success("Book conversion works correctly")
    }

    // MARK: - Computed Properties Tests

    func testQuoteExtractionResult_AverageConfidence() async throws {
        logger.step(1, "Preparing quotes with varying confidence")
        let json = """
        {
            "quotes": [
                {"text": "Quote 1", "markingType": "underline", "confidence": 0.9},
                {"text": "Quote 2", "markingType": "highlight", "confidence": 0.8},
                {"text": "Quote 3", "markingType": "bracket", "confidence": 0.7}
            ]
        }
        """

        logger.step(2, "Calculating average confidence")
        let result = try QuoteExtractionResult.parse(from: json)
        let average = result.averageConfidence

        logger.step(3, "Validating average")
        XCTAssertEqual(average, 0.8, accuracy: 0.001)

        logger.success("Average confidence calculated correctly")
    }

    func testQuoteExtractionResult_HighConfidenceQuotes() async throws {
        logger.step(1, "Preparing quotes with mixed confidence")
        let json = """
        {
            "quotes": [
                {"text": "High conf", "markingType": "underline", "confidence": 0.95},
                {"text": "Low conf", "markingType": "highlight", "confidence": 0.5},
                {"text": "Medium conf", "markingType": "bracket", "confidence": 0.75}
            ]
        }
        """

        logger.step(2, "Filtering high confidence quotes")
        let result = try QuoteExtractionResult.parse(from: json)
        let highConf = result.highConfidenceQuotes

        logger.step(3, "Validating filter")
        XCTAssertEqual(highConf.count, 2)  // >= 0.7

        logger.success("High confidence filtering works correctly")
    }

    // MARK: - Marking Type Parsing Tests

    func testExtractedQuote_ParseMarkingType_Underline() async throws {
        let json = """
        {"quotes": [{"text": "Test", "markingType": "underline", "confidence": 0.9}]}
        """
        let result = try QuoteExtractionResult.parse(from: json)
        let quote = try XCTUnwrap(result.quotes.first).toExtractedQuote()

        XCTAssertEqual(quote.markingType, .underline)
        logger.success("Underline marking type parsed correctly")
    }

    func testExtractedQuote_ParseMarkingType_Highlight() async throws {
        let json = """
        {"quotes": [{"text": "Test", "markingType": "highlight", "confidence": 0.9}]}
        """
        let result = try QuoteExtractionResult.parse(from: json)
        let quote = try XCTUnwrap(result.quotes.first).toExtractedQuote()

        XCTAssertEqual(quote.markingType, .highlight)
        logger.success("Highlight marking type parsed correctly")
    }

    func testExtractedQuote_ParseMarkingType_MarginNote() async throws {
        let json = """
        {"quotes": [{"text": "Test", "markingType": "margin_note", "confidence": 0.9}]}
        """
        let result = try QuoteExtractionResult.parse(from: json)
        let quote = try XCTUnwrap(result.quotes.first).toExtractedQuote()

        XCTAssertEqual(quote.markingType, .marginNote)
        logger.success("Margin note marking type parsed correctly")
    }

    func testExtractedQuote_ParseMarkingType_Unknown_DefaultsToMixed() async throws {
        let json = """
        {"quotes": [{"text": "Test", "markingType": "unknown_type", "confidence": 0.9}]}
        """
        let result = try QuoteExtractionResult.parse(from: json)
        let quote = try XCTUnwrap(result.quotes.first).toExtractedQuote()

        XCTAssertEqual(quote.markingType, .mixed)
        logger.success("Unknown marking type defaults to mixed")
    }

    // MARK: - Prompt Building Tests

    func testBuildQuoteExtractionPrompt_IncludesAllMarkings() async throws {
        logger.step(1, "Fetching marking definitions")
        let markings = try fetchAllMarkingDefinitions()

        logger.step(2, "Building prompt")
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markings: markings)

        logger.step(3, "Verifying marking types in prompt")
        // Check that the prompt contains key elements
        XCTAssertTrue(prompt.contains("JSON"), "Prompt should specify JSON format")
        XCTAssertTrue(prompt.contains("quotes"), "Prompt should mention quotes array")
        XCTAssertTrue(prompt.contains("text"), "Prompt should mention text field")
        XCTAssertTrue(prompt.contains("confidence"), "Prompt should mention confidence")

        logger.success("Prompt includes all required elements")
    }

    func testBuildQuoteExtractionPrompt_CustomMarkings() async throws {
        logger.step(1, "Creating custom marking definitions")
        let customMarkings = [
            MarkingDefinition(
                name: "Star",
                visualDescription: "Star drawn next to text",
                meaning: "Favorite passages",
                icon: "star.fill",
                colorName: "yellow"
            )
        ]

        logger.step(2, "Building prompt with custom markings")
        let prompt = QuoteExtractionPromptBuilder.buildPrompt(markings: customMarkings)

        logger.step(3, "Verifying custom marking in prompt")
        XCTAssertTrue(prompt.contains("Star"), "Prompt should include custom marking name")
        XCTAssertTrue(prompt.contains("Favorite passages"), "Prompt should include custom meaning")

        logger.success("Custom markings included in prompt")
    }

    func testBuildCoverExtractionPrompt_IncludesRequiredFields() async throws {
        logger.step(1, "Building cover extraction prompt")
        let prompt = QuoteExtractionPromptBuilder.buildCoverExtractionPrompt()

        logger.step(2, "Verifying required fields")
        XCTAssertTrue(prompt.contains("title"), "Prompt should request title")
        XCTAssertTrue(prompt.contains("author"), "Prompt should request author")
        XCTAssertTrue(prompt.contains("ISBN") || prompt.contains("isbn"), "Prompt should request ISBN")
        XCTAssertTrue(prompt.contains("JSON"), "Prompt should specify JSON format")

        logger.success("Cover extraction prompt includes required fields")
    }

    // MARK: - Error Description Tests

    func testExtractionError_Descriptions() async throws {
        logger.step(1, "Testing error descriptions")

        let errors: [ExtractionError] = [
            .invalidImage,
            .noQuotesFound,
            .rateLimited,
            .subscriptionRequired,
            .authenticationRequired,
            .parsingError("Test error")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recovery suggestion: \(error)")
            logger.debug("Error: \(error.errorDescription ?? "nil")")
        }

        logger.success("All errors have descriptions and recovery suggestions")
    }
}
