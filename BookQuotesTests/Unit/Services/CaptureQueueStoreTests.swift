import SwiftData
import UIKit
import XCTest

@testable import BookQuotes

@MainActor
final class CaptureQueueStoreTests: SwiftDataTestCase {
    func testEnqueueStoresImageThumbnailPriorityAndStats() async throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let store = CaptureQueueStore(modelContainer: modelContainer)
        let item = try store.enqueue(
            image: testImage(fill: .white),
            book: book,
            priority: 7
        )

        XCTAssertEqual(item.priority, 7)
        XCTAssertEqual(item.status, .pending)
        XCTAssertNotNil(item.thumbnailData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.fullImagePath.path))

        let stats = try store.stats(isProcessing: false)
        XCTAssertEqual(stats.pendingCount, 1)
        XCTAssertEqual(stats.totalActive, 1)
        XCTAssertEqual(try store.nextPendingItemID(), item.id)
    }

    func testRetryCancelAndRemovePreserveQueueMutationBehavior() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(book: book, imagePath: "queued.jpg")
        item.status = .failed
        item.retryCount = 1
        item.lastError = "Transient failure"
        modelContext.insert(item)
        try modelContext.save()

        let store = CaptureQueueStore(modelContainer: modelContainer)

        try store.retryItem(id: item.id)
        var persisted = try XCTUnwrap(fetchItem(id: item.id))
        XCTAssertEqual(persisted.status, .pending)
        XCTAssertNil(persisted.lastError)

        try store.cancelItem(id: item.id)
        persisted = try XCTUnwrap(fetchItem(id: item.id))
        XCTAssertEqual(persisted.status, .cancelled)

        try store.removeItem(id: item.id)
        let remaining = try ModelContext(modelContainer).fetch(FetchDescriptor<CaptureQueueItem>())
        XCTAssertTrue(remaining.isEmpty)
    }

    private func fetchItem(id itemId: UUID) throws -> CaptureQueueItem? {
        let context = ModelContext(modelContainer)
        return try context.fetch(CaptureQueueFetch.itemDescriptor(id: itemId)).first
    }

    private func testImage(fill: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 180))
        return renderer.image { context in
            fill.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 180))
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 20, y: 44, width: 80, height: 8))
        }
    }
}
