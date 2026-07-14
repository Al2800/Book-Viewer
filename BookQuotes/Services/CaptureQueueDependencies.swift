import Foundation
import UIKit

protocol CaptureQueueStoring {
    func enqueue(
        image: UIImage,
        book: Book,
        priority: Int
    ) throws -> CaptureQueueItem

    func removeItem(id itemId: UUID) throws
    func retryItem(id itemId: UUID) throws
    func cancelItem(id itemId: UUID) throws
    func cleanupOldItems() throws
    func recoverInterruptedItems() throws
    func stats(isProcessing: Bool) throws -> QueueStats
    func nextPendingItemID() throws -> UUID?
    func canRetryItem(id itemId: UUID) throws -> Bool
}

protocol CaptureQueueItemProcessing {
    func process(
        itemId: UUID,
        onStateChanged: () async -> Void
    ) async -> CaptureQueueProcessingOutcome
}

extension CaptureQueueStore: CaptureQueueStoring {}
extension CaptureQueueItemProcessor: CaptureQueueItemProcessing {}
