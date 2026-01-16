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
}
