import XCTest
import SwiftData
import UIKit

@testable import BookQuotes

@MainActor
final class QuoteCaptureSessionStoreTests: SwiftDataTestCase {
    func testCreateSessionPersistsSinglePendingPageForCapturedImage() async throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let store = QuoteCaptureSessionStore(modelContext: modelContext)
        let session = try await store.createSession(
            for: book,
            image: testImage(),
            seedForUITest: false
        )

        XCTAssertEqual(session.book?.id, book.id)
        XCTAssertEqual(session.status, .readyToProcess)
        XCTAssertEqual(session.totalPages, 1)
        XCTAssertEqual(session.pendingPages, 1)
        XCTAssertEqual(session.captures.count, 1)

        let pageCapture = try XCTUnwrap(session.captures.first)
        XCTAssertEqual(pageCapture.orderIndex, 0)
        XCTAssertEqual(pageCapture.status, .pending)
        XCTAssertNotNil(pageCapture.thumbnailData)
        XCTAssertFalse(pageCapture.imagePath.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: try XCTUnwrap(pageCapture.imageURL).path))
    }

    func testCreateSessionCanSeedExtractionForUITestReviewFlow() async throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let store = QuoteCaptureSessionStore(modelContext: modelContext)
        let session = try await store.createSession(
            for: book,
            image: testImage(),
            seedForUITest: true
        )

        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.processedPages, 1)
        XCTAssertEqual(session.pendingPages, 0)
        XCTAssertEqual(session.totalQuotesExtracted, 1)

        let pageCapture = try XCTUnwrap(session.captures.first)
        XCTAssertEqual(pageCapture.status, .completed)
        XCTAssertEqual(pageCapture.extractedQuoteCount, 1)
        XCTAssertEqual(pageCapture.detectedPageNumber, 12)
        XCTAssertEqual(pageCapture.loadExtractedQuotes().first?.text, "Test quote extracted for UI testing.")
    }

    private func testImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 180))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 180))
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 18, y: 40, width: 84, height: 8))
            context.cgContext.fill(CGRect(x: 18, y: 58, width: 70, height: 8))
        }
    }
}
