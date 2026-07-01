import Foundation

struct CaptureQueueRetryScheduler {
    private var pendingRetries: [UUID: Task<Void, Never>] = [:]

    var pendingRetryCount: Int {
        pendingRetries.count
    }

    func hasPendingRetry(for itemId: UUID) -> Bool {
        pendingRetries[itemId] != nil
    }

    mutating func schedule(_ task: Task<Void, Never>, for itemId: UUID) {
        cancelRetry(for: itemId)
        pendingRetries[itemId] = task
    }

    mutating func cancelRetry(for itemId: UUID) {
        pendingRetries[itemId]?.cancel()
        pendingRetries.removeValue(forKey: itemId)
    }

    mutating func cancelAll() {
        for task in pendingRetries.values {
            task.cancel()
        }
        pendingRetries.removeAll()
    }
}
