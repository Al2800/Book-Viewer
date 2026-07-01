import Foundation

/// Statistics about the capture queue state.
struct QueueStats: Equatable, Sendable {
    /// Number of items waiting to be processed
    var pendingCount: Int = 0

    /// Number of items currently being processed
    var processingCount: Int = 0

    /// Number of items that failed and cannot be retried
    var failedCount: Int = 0

    /// Number of successfully completed items
    var completedCount: Int = 0

    /// Whether the queue is actively processing
    var isProcessing: Bool = false

    /// Total items in queue (excluding completed)
    var totalActive: Int {
        pendingCount + processingCount + failedCount
    }

    /// Whether there are any items needing attention
    var hasActiveItems: Bool {
        totalActive > 0
    }

    /// Human-readable status
    var statusDescription: String {
        if isProcessing {
            return "Processing \(processingCount) of \(totalActive)"
        } else if pendingCount > 0 {
            return "\(pendingCount) waiting"
        } else if failedCount > 0 {
            return "\(failedCount) failed"
        } else {
            return "Queue empty"
        }
    }
}

/// Errors that can occur during queue operations.
enum QueueError: LocalizedError {
    case imageStorageFailed
    case imageLoadFailed
    case bookNotFound
    case itemNotFound
    case processingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .imageStorageFailed:
            return "Failed to save captured image"
        case .imageLoadFailed:
            return "Failed to load image from storage"
        case .bookNotFound:
            return "The associated book was not found"
        case .itemNotFound:
            return "Queue item not found"
        case .processingFailed(let error):
            return "Processing failed: \(error.localizedDescription)"
        }
    }
}
