import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - PageCaptureTests

@MainActor
final class PageCaptureTests: SwiftDataTestCase {

    func testStatusTransitions() {
        let capture = PageCapture(imagePath: "captures/test.jpg")
        XCTAssertEqual(capture.status, .pending)

        capture.beginProcessing()
        XCTAssertEqual(capture.status, .processing)

        capture.completeProcessing(quoteCount: 2, avgConfidence: 0.8, pageNumber: 12)
        XCTAssertEqual(capture.status, .completed)
        XCTAssertEqual(capture.extractedQuoteCount, 2)
        XCTAssertEqual(capture.averageConfidence, 0.8)
        XCTAssertEqual(capture.detectedPageNumber, 12)
        XCTAssertNotNil(capture.dateProcessed)
    }

    func testFailureAndRetryFlow() {
        let capture = PageCapture(imagePath: "captures/test.jpg")
        capture.beginProcessing()
        capture.failProcessing(error: "Network error")

        XCTAssertEqual(capture.status, .failed)
        XCTAssertEqual(capture.errorMessage, "Network error")
        XCTAssertTrue(capture.canRetry)

        capture.resetForRetry()
        XCTAssertEqual(capture.status, .pending)
        XCTAssertNil(capture.errorMessage)
        XCTAssertEqual(capture.extractedQuoteCount, 0)
    }

    func testStoreAndLoadExtractedQuotes() {
        let capture = PageCapture(imagePath: "captures/test.jpg")
        let quotes = [
            ExtractedQuoteData(text: "Quote A", pageNumber: 1, marginNote: nil, markingType: "underline", confidence: 0.9),
            ExtractedQuoteData(text: "Quote B", pageNumber: 2, marginNote: "Note", markingType: "highlight", confidence: 0.8)
        ]

        capture.storeExtractedQuotes(quotes)
        let loaded = capture.loadExtractedQuotes()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(capture.extractedQuoteCount, 2)
        XCTAssertNotNil(capture.averageConfidence)
    }

    func testCompleteExtractionStoresNonEmptyResult() throws {
        let capture = PageCapture(imagePath: "captures/test.jpg")
        capture.beginProcessing()
        let result = QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "A marked passage",
                    pageNumber: 42,
                    marginNote: nil,
                    markingType: "underline",
                    confidence: 0.91
                )
            ],
            pageNumber: 42,
            processingNotes: "clear marking"
        )

        try capture.completeExtraction(with: result)

        XCTAssertEqual(capture.status, .completed)
        XCTAssertEqual(capture.extractedQuoteCount, 1)
        XCTAssertEqual(capture.detectedPageNumber, 42)
        XCTAssertEqual(capture.loadExtractedQuotes().first?.text, "A marked passage")
    }

    func testCompleteExtractionFailsForEmptyResult() {
        let capture = PageCapture(imagePath: "captures/test.jpg")
        capture.beginProcessing()
        let result = QuoteExtractionResult(
            quotes: [],
            pageNumber: nil,
            processingNotes: "No marked passages found"
        )

        XCTAssertThrowsError(try capture.completeExtraction(with: result)) { error in
            guard case ExtractionError.noQuotesFound = error else {
                return XCTFail("Expected noQuotesFound, got \(error)")
            }
        }
        XCTAssertEqual(capture.status, .processing)
        XCTAssertEqual(capture.extractedQuoteCount, 0)
        XCTAssertTrue(capture.loadExtractedQuotes().isEmpty)
    }
}
