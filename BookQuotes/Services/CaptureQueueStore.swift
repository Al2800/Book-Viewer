import Foundation
import SwiftData
import UIKit

struct CaptureQueueStore {
    let modelContainer: ModelContainer

    func enqueue(
        image: UIImage,
        book: Book,
        priority: Int = 0
    ) throws -> CaptureQueueItem {
        guard let imagePath = CaptureQueueItem.saveImage(image) else {
            throw QueueError.imageStorageFailed
        }

        let context = ModelContext(modelContainer)
        guard let contextBook = try fetchBook(id: book.id, in: context) else {
            throw QueueError.bookNotFound
        }

        let item = CaptureQueueItem(
            book: contextBook,
            imagePath: imagePath,
            thumbnailData: CaptureQueueItem.generateThumbnail(from: image),
            priority: priority
        )
        context.insert(item)
        try context.save()
        return item
    }

    func removeItem(id itemId: UUID) throws {
        let context = ModelContext(modelContainer)
        guard let item = try fetchItem(id: itemId, in: context) else { return }

        item.deleteImageFile()
        context.delete(item)
        try context.save()
    }

    func retryItem(id itemId: UUID) throws {
        let context = ModelContext(modelContainer)
        guard let item = try fetchItem(id: itemId, in: context) else {
            throw QueueError.itemNotFound
        }

        item.resetForRetry()
        try context.save()
    }

    func cancelItem(id itemId: UUID) throws {
        let context = ModelContext(modelContainer)
        guard let item = try fetchItem(id: itemId, in: context) else { return }

        item.cancel()
        try context.save()
    }

    func cleanupOldItems() throws {
        let context = ModelContext(modelContainer)
        let items = try context.fetch(CaptureQueueItem.cleanupDescriptor)

        for item in items {
            item.deleteImageFile()
            context.delete(item)
        }

        try context.save()
    }

    func stats(isProcessing: Bool) throws -> QueueStats {
        let context = ModelContext(modelContainer)
        let items = try context.fetch(FetchDescriptor<CaptureQueueItem>())
        return CaptureQueueStatsBuilder.stats(from: items, isProcessing: isProcessing)
    }

    func nextPendingItemID() throws -> UUID? {
        let context = ModelContext(modelContainer)
        return try context.fetch(CaptureQueueFetch.nextPendingDescriptor).first?.id
    }

    func canRetryItem(id itemId: UUID) throws -> Bool {
        let context = ModelContext(modelContainer)
        return try fetchItem(id: itemId, in: context)?.canRetry ?? false
    }

    private func fetchBook(id bookId: UUID, in context: ModelContext) throws -> Book? {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.id == bookId }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchItem(id itemId: UUID, in context: ModelContext) throws -> CaptureQueueItem? {
        try context.fetch(CaptureQueueFetch.itemDescriptor(id: itemId)).first
    }
}
