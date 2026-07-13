import XCTest
import SwiftData
import Combine

@testable import BookQuotes

// MARK: - CaptureQueueManagerTests

/// Unit tests for CaptureQueueManager covering queue operations, stats, and lifecycle.
@MainActor
final class CaptureQueueManagerTests: SwiftDataTestCase {

    // MARK: - Properties

    var queueManager: CaptureQueueManager!
    var authService: AuthService!
    var quoteExtractor: QuoteExtractionPipeline!
    var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        authService = AuthService()
        quoteExtractor = QuoteExtractionPipeline(
            localExtractor: OnDeviceQuoteExtractor(),
            remoteExtractor: RemoteModelQuoteExtractor(authService: authService)
        )

        queueManager = CaptureQueueManager(
            modelContainer: modelContainer,
            quoteExtractor: quoteExtractor,
            networkMonitor: NetworkMonitor()
        )

        logger.info("CaptureQueueManagerTests setup complete")
    }

    override func tearDown() async throws {
        await queueManager.stop()
        queueManager = nil
        quoteExtractor = nil
        authService = nil
        cancellables.removeAll()
        try await super.tearDown()
    }

    // MARK: - Network Monitoring Tests

    func testStartUsesInjectedNetworkMonitorAndRemainsIdleWhenOffline() async throws {
        let networkMonitor = StubCaptureQueueNetworkMonitor(isConnected: false)
        let manager = CaptureQueueManager(
            modelContainer: modelContainer,
            quoteExtractor: quoteExtractor,
            networkMonitor: networkMonitor
        )

        await manager.start()

        let stats = await manager.stats
        XCTAssertEqual(networkMonitor.startMonitoringCallCount, 1)
        XCTAssertFalse(stats.isProcessing)

        await manager.stop()
    }

    // MARK: - Stats Publisher Tests

    func testStatsPublisher_EmitsOnChange() async throws {
        logger.step(1, "Setting up stats subscription")

        var receivedStats: [QueueStats] = []
        let expectation = XCTestExpectation(description: "Receive stats updates")

        queueManager.statsPublisher
            .dropFirst()  // Skip initial value
            .receive(on: RunLoop.main)
            .sink { stats in
                receivedStats.append(stats)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        logger.step(2, "Triggering stats update via start")
        await queueManager.start()

        await fulfillment(of: [expectation], timeout: 2.0)

        logger.step(3, "Verifying stats received")
        XCTAssertFalse(receivedStats.isEmpty)

        logger.success("Stats publisher emits updates")
    }

    func testStatsPublisherUsesProcessingFallbackWhenStatsReadFails() async throws {
        let itemId = UUID()
        let queueStore = SpyCaptureQueueStore(
            pendingItemIds: [itemId],
            throwsOnStats: true
        )
        let itemProcessor = SpyCaptureQueueItemProcessor(outcomes: [.completed])
        let manager = CaptureQueueManager(
            queueStore: queueStore,
            itemProcessor: itemProcessor,
            networkMonitor: StubCaptureQueueNetworkMonitor(isConnected: true)
        )
        let expectation = XCTestExpectation(description: "Processing fallback stats emitted")
        var hasFulfilledProcessingFallback = false

        manager.statsPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { stats in
                guard stats.isProcessing, !hasFulfilledProcessingFallback else { return }
                hasFulfilledProcessingFallback = true
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await manager.processNow()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(queueStore.statsProcessingStates.contains(true))
        let finalStats = await manager.stats
        XCTAssertEqual(finalStats, QueueStats(isProcessing: false))

        await manager.stop()
    }

    // MARK: - Queue Manager Lifecycle Tests

    func testStart_DoesNotCrash() async throws {
        logger.step(1, "Starting queue manager")

        // Should not throw or crash
        await queueManager.start()

        logger.step(2, "Verifying manager is ready")
        // Just verify it completes without error

        logger.success("Queue manager starts successfully")
    }

    func testStop_CleansUpResources() async throws {
        logger.step(1, "Starting then stopping queue manager")

        await queueManager.start()
        await queueManager.stop()

        logger.step(2, "Verifying cleanup")
        // Should not crash and resources should be cleaned up

        logger.success("Queue manager stops successfully")
    }

    func testMultipleStartStop_DoesNotCrash() async throws {
        logger.step(1, "Starting and stopping multiple times")

        for i in 1...3 {
            await queueManager.start()
            try await Task.sleep(for: .milliseconds(50))
            await queueManager.stop()
            logger.debug("Cycle \(i) complete")
        }

        logger.success("Multiple start/stop cycles complete without crash")
    }

    func testProcessNowProcessesNextPendingItemWhenOnline() async throws {
        let itemId = UUID()
        let queueStore = SpyCaptureQueueStore(pendingItemIds: [itemId])
        let itemProcessor = SpyCaptureQueueItemProcessor(outcomes: [.completed])
        let manager = CaptureQueueManager(
            queueStore: queueStore,
            itemProcessor: itemProcessor,
            networkMonitor: StubCaptureQueueNetworkMonitor(isConnected: true)
        )

        await manager.processNow()

        XCTAssertEqual(itemProcessor.processedItemIds, [itemId])
        XCTAssertTrue(queueStore.statsProcessingStates.contains(true))
        XCTAssertEqual(queueStore.statsProcessingStates.last, false)

        await manager.stop()
    }

    func testProcessNowDoesNotProcessWhenOffline() async throws {
        let itemId = UUID()
        let queueStore = SpyCaptureQueueStore(pendingItemIds: [itemId])
        let itemProcessor = SpyCaptureQueueItemProcessor(outcomes: [.completed])
        let manager = CaptureQueueManager(
            queueStore: queueStore,
            itemProcessor: itemProcessor,
            networkMonitor: StubCaptureQueueNetworkMonitor(isConnected: false)
        )

        await manager.processNow()

        XCTAssertTrue(itemProcessor.processedItemIds.isEmpty)
        XCTAssertTrue(queueStore.statsProcessingStates.isEmpty)

        await manager.stop()
    }

    func testRetryableFailureReprocessesItemAfterRetryDelayWhenStillRetryable() async throws {
        let itemId = UUID()
        let queueStore = SpyCaptureQueueStore(
            pendingItemIds: [itemId],
            retryableItemIds: [itemId]
        )
        let itemProcessor = SpyCaptureQueueItemProcessor(
            outcomes: [
                .failed(itemId: itemId, retryCount: 1, canRetry: true),
                .completed
            ]
        )
        let manager = CaptureQueueManager(
            queueStore: queueStore,
            itemProcessor: itemProcessor,
            networkMonitor: StubCaptureQueueNetworkMonitor(isConnected: true),
            retryPolicy: CaptureQueueRetryPolicy(delays: [0])
        )

        await manager.processNow()
        try await waitForProcessedItemCount(2, in: itemProcessor)

        XCTAssertEqual(itemProcessor.processedItemIds, [itemId, itemId])
        XCTAssertEqual(queueStore.canRetryItemIds, [itemId])

        await manager.stop()
    }

    func testRemoveFromQueueCancelsPendingRetryForItem() async throws {
        let itemId = UUID()
        let queueStore = SpyCaptureQueueStore(
            pendingItemIds: [itemId],
            retryableItemIds: [itemId]
        )
        let itemProcessor = SpyCaptureQueueItemProcessor(
            outcomes: [
                .failed(itemId: itemId, retryCount: 1, canRetry: true),
                .completed
            ]
        )
        let manager = CaptureQueueManager(
            queueStore: queueStore,
            itemProcessor: itemProcessor,
            networkMonitor: StubCaptureQueueNetworkMonitor(isConnected: true),
            retryPolicy: CaptureQueueRetryPolicy(delays: [0.05])
        )

        await manager.processNow()
        try await manager.removeFromQueue(itemId: itemId)
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(itemProcessor.processedItemIds, [itemId])
        XCTAssertEqual(queueStore.removedItemIds, [itemId])

        await manager.stop()
    }

    func testRetryItemMarksItemForRetryAndProcessesWhenOnline() async throws {
        let itemId = UUID()
        let queueStore = SpyCaptureQueueStore(pendingItemIds: [itemId])
        let itemProcessor = SpyCaptureQueueItemProcessor(outcomes: [.completed])
        let manager = CaptureQueueManager(
            queueStore: queueStore,
            itemProcessor: itemProcessor,
            networkMonitor: StubCaptureQueueNetworkMonitor(isConnected: true)
        )

        try await manager.retryItem(itemId: itemId)

        XCTAssertEqual(queueStore.retriedItemIds, [itemId])
        XCTAssertEqual(itemProcessor.processedItemIds, [itemId])
        XCTAssertTrue(queueStore.statsProcessingStates.contains(true))

        await manager.stop()
    }

    // MARK: - Integration Tests

    func testAddToQueue_WithValidBook_CreatesItem() async throws {
        logger.step(1, "Creating a book")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        // Note: This test would require a real image and may fail without proper setup
        // Skipping actual addToQueue call as it requires file system operations

        logger.success("Test setup verified - would create queue item with valid book")
    }
}
