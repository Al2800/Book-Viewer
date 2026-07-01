import Foundation
import UIKit
import XCTest

@testable import BookQuotes

@MainActor
final class StubCaptureQueueNetworkMonitor: CaptureQueueNetworkMonitoring {
    private(set) var startMonitoringCallCount = 0
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    func startMonitoring() {
        startMonitoringCallCount += 1
    }
}

final class SpyCaptureQueueStore: CaptureQueueStoring, @unchecked Sendable {
    enum StoreError: Error {
        case statsUnavailable
    }

    private let lock = NSLock()
    private var pendingItemIds: [UUID]
    private let retryableItemIds: Set<UUID>
    private let throwsOnStats: Bool
    private var storedStatsProcessingStates: [Bool] = []
    private var storedCanRetryItemIds: [UUID] = []
    private var storedRemovedItemIds: [UUID] = []
    private var storedRetriedItemIds: [UUID] = []

    var statsProcessingStates: [Bool] {
        locked { storedStatsProcessingStates }
    }

    var canRetryItemIds: [UUID] {
        locked { storedCanRetryItemIds }
    }

    var removedItemIds: [UUID] {
        locked { storedRemovedItemIds }
    }

    var retriedItemIds: [UUID] {
        locked { storedRetriedItemIds }
    }

    init(
        pendingItemIds: [UUID],
        retryableItemIds: Set<UUID> = [],
        throwsOnStats: Bool = false
    ) {
        self.pendingItemIds = pendingItemIds
        self.retryableItemIds = retryableItemIds
        self.throwsOnStats = throwsOnStats
    }

    func enqueue(
        image: UIImage,
        book: Book,
        priority: Int
    ) throws -> CaptureQueueItem {
        throw QueueError.itemNotFound
    }

    func removeItem(id itemId: UUID) throws {
        locked {
            storedRemovedItemIds.append(itemId)
        }
    }

    func retryItem(id itemId: UUID) throws {
        locked {
            storedRetriedItemIds.append(itemId)
        }
    }

    func cancelItem(id itemId: UUID) throws {}

    func cleanupOldItems() throws {}

    func stats(isProcessing: Bool) throws -> QueueStats {
        locked {
            storedStatsProcessingStates.append(isProcessing)
        }
        if throwsOnStats {
            throw StoreError.statsUnavailable
        }
        return QueueStats(isProcessing: isProcessing)
    }

    func nextPendingItemID() throws -> UUID? {
        locked {
            guard !pendingItemIds.isEmpty else { return nil }
            return pendingItemIds.removeFirst()
        }
    }

    func canRetryItem(id itemId: UUID) throws -> Bool {
        locked {
            storedCanRetryItemIds.append(itemId)
        }
        return retryableItemIds.contains(itemId)
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

final class SpyCaptureQueueItemProcessor: CaptureQueueItemProcessing, @unchecked Sendable {
    private let lock = NSLock()
    private var outcomes: [CaptureQueueProcessingOutcome]
    private var storedProcessedItemIds: [UUID] = []

    var processedItemIds: [UUID] {
        locked { storedProcessedItemIds }
    }

    init(outcomes: [CaptureQueueProcessingOutcome]) {
        self.outcomes = outcomes
    }

    func process(
        itemId: UUID,
        onStateChanged: () async -> Void
    ) async -> CaptureQueueProcessingOutcome {
        locked {
            storedProcessedItemIds.append(itemId)
        }
        await onStateChanged()

        return locked {
            guard !outcomes.isEmpty else {
                return .completed
            }

            return outcomes.removeFirst()
        }
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

func waitForProcessedItemCount(
    _ expectedCount: Int,
    in processor: SpyCaptureQueueItemProcessor,
    timeout: TimeInterval = 1.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async throws {
    let deadline = Date().addingTimeInterval(timeout)

    while processor.processedItemIds.count < expectedCount && Date() < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertEqual(
        processor.processedItemIds.count,
        expectedCount,
        file: file,
        line: line
    )
}
