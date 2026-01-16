import XCTest
import SwiftData
import UIKit

@testable import BookQuotes

// MARK: - CaptureQueueItemTests

@MainActor
final class CaptureQueueItemTests: SwiftDataTestCase {

    func testStatusTransitions() {
        let book = TestFixtures.book()
        let item = CaptureQueueItem(book: book, imagePath: "test.jpg")

        XCTAssertEqual(item.status, .pending)
        item.markProcessing()
        XCTAssertEqual(item.status, .processing)
        XCTAssertNotNil(item.dateLastAttempt)

        let quote = TestFixtures.quote { builder in builder.book = book }
        item.markCompleted(quotes: [quote])
        XCTAssertEqual(item.status, .completed)
        XCTAssertNotNil(item.dateCompleted)
        XCTAssertNil(item.lastError)
        XCTAssertEqual(item.extractedQuotes?.count, 1)
    }

    func testFailureAndRetryLogic() {
        let book = TestFixtures.book()
        let item = CaptureQueueItem(book: book, imagePath: "test.jpg")

        struct TestError: Error { }
        item.markFailed(error: TestError())

        XCTAssertEqual(item.status, .failed)
        XCTAssertEqual(item.retryCount, 1)
        XCTAssertTrue(item.canRetry)

        item.markPermanentlyFailed(error: TestError())
        XCTAssertEqual(item.retryCount, CaptureQueueItem.maxRetries)
        XCTAssertFalse(item.canRetry)
    }

    func testCleanupEligibility() {
        let book = TestFixtures.book()
        let item = CaptureQueueItem(book: book, imagePath: "test.jpg")
        item.status = .completed
        item.dateCompleted = Date().addingTimeInterval(-CaptureQueueItem.completedRetentionHours * 3600 - 10)

        XCTAssertTrue(item.isEligibleForCleanup)
    }

    func testThumbnailGeneration() {
        let imageData = TestFixtures.TestImages.bookCover
        let image = UIImage(data: imageData)
        let thumbnail = CaptureQueueItem.generateThumbnail(from: image ?? UIImage(), maxSize: 80)

        XCTAssertNotNil(thumbnail)
    }
}
