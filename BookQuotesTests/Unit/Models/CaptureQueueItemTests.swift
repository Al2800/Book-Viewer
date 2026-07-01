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

    func testInitialState() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        modelContext.insert(item)
        try modelContext.save()

        XCTAssertEqual(item.status, .pending)
        XCTAssertEqual(item.retryCount, 0)
        XCTAssertNil(item.lastError)
        XCTAssertNil(item.dateCompleted)
        XCTAssertNotNil(item.dateQueued)
    }

    func testMarkProcessing() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        modelContext.insert(item)
        try modelContext.save()

        item.markProcessing()

        XCTAssertEqual(item.status, .processing)
    }

    func testMarkFailedIncrementsRetry() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        modelContext.insert(item)
        try modelContext.save()

        item.markFailed(error: QueueError.processingFailed(NSError(domain: "test", code: 1)))

        XCTAssertEqual(item.retryCount, 1)
        XCTAssertNotNil(item.lastError)
    }

    func testMarkFailedExceedsMaxRetries() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        item.retryCount = CaptureQueueItem.maxRetries - 1
        modelContext.insert(item)
        try modelContext.save()

        item.markFailed(error: QueueError.processingFailed(NSError(domain: "test", code: 1)))

        XCTAssertEqual(item.status, .failed)
        XCTAssertEqual(item.retryCount, CaptureQueueItem.maxRetries)
    }

    func testResetForRetryClearsErrorStateButPreservesRetryCount() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        item.status = .failed
        item.retryCount = 2
        item.lastError = "Previous error"
        modelContext.insert(item)
        try modelContext.save()

        item.resetForRetry()

        XCTAssertEqual(item.status, .pending)
        XCTAssertEqual(item.retryCount, 2)
        XCTAssertNil(item.lastError)
    }

    func testCancelUpdatesStatus() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        item.status = .processing
        modelContext.insert(item)
        try modelContext.save()

        item.cancel()

        XCTAssertEqual(item.status, .cancelled)
    }

    func testCanRetryIsTrueForFailedItems() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        item.status = .failed
        modelContext.insert(item)
        try modelContext.save()

        XCTAssertTrue(item.canRetry)
    }

    func testCanRetryIsFalseForCompletedItems() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(
            book: book,
            imagePath: "test/path.jpg",
            thumbnailData: nil,
            priority: 0
        )
        item.status = .completed
        modelContext.insert(item)
        try modelContext.save()

        XCTAssertFalse(item.canRetry)
    }

    func testPendingDescriptorFetchesPendingOnly() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let pendingItem = CaptureQueueItem(book: book, imagePath: "p1.jpg", thumbnailData: nil, priority: 0)
        pendingItem.status = .pending

        let processingItem = CaptureQueueItem(book: book, imagePath: "p2.jpg", thumbnailData: nil, priority: 0)
        processingItem.status = .processing

        let completedItem = CaptureQueueItem(book: book, imagePath: "p3.jpg", thumbnailData: nil, priority: 0)
        completedItem.status = .completed

        let failedItem = CaptureQueueItem(book: book, imagePath: "p4.jpg", thumbnailData: nil, priority: 0)
        failedItem.status = .failed

        modelContext.insert(pendingItem)
        modelContext.insert(processingItem)
        modelContext.insert(completedItem)
        modelContext.insert(failedItem)
        try modelContext.save()

        let pending = try modelContext.fetch(CaptureQueueItem.pendingDescriptor)

        XCTAssertEqual(pending.count, 1)
        XCTAssertEqual(pending.first?.status, .pending)
    }

    func testFailedDescriptorFetchesFailedOnly() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let pendingItem = CaptureQueueItem(book: book, imagePath: "p1.jpg", thumbnailData: nil, priority: 0)
        pendingItem.status = .pending

        let failedItem = CaptureQueueItem(book: book, imagePath: "p2.jpg", thumbnailData: nil, priority: 0)
        failedItem.status = .failed

        modelContext.insert(pendingItem)
        modelContext.insert(failedItem)
        try modelContext.save()

        let failed = try modelContext.fetch(CaptureQueueItem.failedDescriptor)

        XCTAssertEqual(failed.count, 1)
        XCTAssertEqual(failed.first?.status, .failed)
    }
}
