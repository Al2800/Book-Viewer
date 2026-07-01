import Foundation
import SwiftData

struct CaptureQueueRetryPolicy: Equatable {
    let delays: [TimeInterval]

    static let standard = CaptureQueueRetryPolicy(delays: [5, 30, 120])

    func delay(for retryCount: Int) -> TimeInterval {
        guard let firstDelay = delays.first else { return 0 }

        let delayIndex = max(0, min(retryCount - 1, delays.count - 1))
        return delays.indices.contains(delayIndex) ? delays[delayIndex] : firstDelay
    }
}

enum CaptureQueueProcessingStartReason: CaseIterable {
    case managerStart
    case itemQueued
    case manualRequest
    case itemRetryRequested
    case retryDelayElapsed

    static var manualReasons: [CaptureQueueProcessingStartReason] {
        [.manualRequest, .itemRetryRequested, .retryDelayElapsed]
    }
}

enum CaptureQueueProcessingStartPolicy {
    static func shouldStartProcessing(
        reason: CaptureQueueProcessingStartReason,
        isConnected: Bool,
        isAutoProcessEnabled: Bool
    ) -> Bool {
        guard isConnected else { return false }

        switch reason {
        case .managerStart, .itemQueued:
            return isAutoProcessEnabled
        case .manualRequest, .itemRetryRequested, .retryDelayElapsed:
            return true
        }
    }
}

enum CaptureQueueFetch {
    static func itemDescriptor(id: UUID) -> FetchDescriptor<CaptureQueueItem> {
        FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { $0.id == id }
        )
    }

    static var nextPendingDescriptor: FetchDescriptor<CaptureQueueItem> {
        var descriptor = CaptureQueueItem.pendingDescriptor
        descriptor.fetchLimit = 1
        return descriptor
    }
}

enum CaptureQueueStatsBuilder {
    static func stats(from items: [CaptureQueueItem], isProcessing: Bool) -> QueueStats {
        var pendingCount = 0
        var processingCount = 0
        var failedCount = 0
        var completedCount = 0

        for item in items {
            switch item.status {
            case .pending:
                pendingCount += 1
            case .processing:
                processingCount += 1
            case .failed:
                failedCount += 1
            case .completed:
                completedCount += 1
            case .cancelled:
                break
            }
        }

        return QueueStats(
            pendingCount: pendingCount,
            processingCount: processingCount,
            failedCount: failedCount,
            completedCount: completedCount,
            isProcessing: isProcessing
        )
    }
}
