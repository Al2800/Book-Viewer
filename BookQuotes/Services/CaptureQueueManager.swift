import Foundation
import SwiftData
import UIKit
import Combine

// MARK: - CaptureQueueManager

/// Orchestrates offline capture queue processing.
/// Monitors network connectivity and processes queued items automatically when online.
/// Uses exponential backoff for retries and provides real-time queue statistics.
actor CaptureQueueManager {

    // MARK: - Dependencies

    private let networkMonitor: any CaptureQueueNetworkMonitoring
    private let itemProcessor: any CaptureQueueItemProcessing
    private let queueStore: any CaptureQueueStoring
    private let processingPreferences: CaptureQueueProcessingPreferences
    private let networkPoller: any CaptureQueueNetworkPolling

    // MARK: - Configuration

    private var isAutoProcessEnabled: Bool {
        processingPreferences.isAutoProcessEnabled
    }

    // MARK: - State

    private var isProcessing = false
    private var processingTask: Task<Void, Never>?
    private var networkObservation: Task<Void, Never>?
    private var retryCoordinator: CaptureQueueRetryCoordinator

    /// Published queue statistics for UI binding
    nonisolated(unsafe) private let statsReporter = CaptureQueueStatsReporter()

    // MARK: - Initialization

    init(
        modelContainer: ModelContainer,
        quoteExtractor: any QuoteExtracting,
        networkMonitor: any CaptureQueueNetworkMonitoring,
        processingPreferences: CaptureQueueProcessingPreferences = CaptureQueueProcessingPreferences(),
        networkPoller: any CaptureQueueNetworkPolling = CaptureQueueNetworkPoller(),
        retryPolicy: CaptureQueueRetryPolicy = .standard
    ) {
        self.networkMonitor = networkMonitor
        self.processingPreferences = processingPreferences
        self.networkPoller = networkPoller
        self.retryCoordinator = CaptureQueueRetryCoordinator(retryPolicy: retryPolicy)
        self.itemProcessor = CaptureQueueItemProcessor(
            modelContainer: modelContainer,
            quoteExtractor: quoteExtractor
        )
        self.queueStore = CaptureQueueStore(modelContainer: modelContainer)
    }

    init(
        queueStore: any CaptureQueueStoring,
        itemProcessor: any CaptureQueueItemProcessing,
        networkMonitor: any CaptureQueueNetworkMonitoring,
        processingPreferences: CaptureQueueProcessingPreferences = CaptureQueueProcessingPreferences(),
        networkPoller: any CaptureQueueNetworkPolling = CaptureQueueNetworkPoller(),
        retryPolicy: CaptureQueueRetryPolicy = .standard
    ) {
        self.queueStore = queueStore
        self.itemProcessor = itemProcessor
        self.networkMonitor = networkMonitor
        self.processingPreferences = processingPreferences
        self.networkPoller = networkPoller
        self.retryCoordinator = CaptureQueueRetryCoordinator(retryPolicy: retryPolicy)
    }

    // MARK: - Lifecycle

    /// Start monitoring network and processing queue.
    /// Call this when the app becomes active.
    func start() async {
        // Start network observation
        await startNetworkObservation()

        // Initial stats update
        await updateStats()

        if await shouldStartProcessing(reason: .managerStart) {
            await startProcessing()
        }
    }

    /// Manually trigger queue processing.
    /// Use this when auto-process is disabled but user wants to process now.
    func processNow() async {
        if await shouldStartProcessing(reason: .manualRequest) {
            await startProcessing()
        }
    }

    /// Stop all processing and monitoring.
    /// Call this when the app enters background.
    func stop() {
        processingTask?.cancel()
        processingTask = nil
        networkObservation?.cancel()
        networkObservation = nil

        retryCoordinator.cancelAll()
    }

    // MARK: - Queue Management

    /// Add a captured image to the processing queue.
    /// - Parameters:
    ///   - image: The captured page image
    ///   - book: The book to associate quotes with
    ///   - priority: Higher priority items are processed first (default 0)
    /// - Returns: The created queue item
    @discardableResult
    func addToQueue(
        image: UIImage,
        book: Book,
        priority: Int = 0
    ) async throws -> CaptureQueueItem {
        return try await performQueueMutation(startReason: .itemQueued) {
            try queueStore.enqueue(image: image, book: book, priority: priority)
        }
    }

    /// Remove an item from the queue and delete its image file.
    /// - Parameter itemId: The ID of the item to remove
    func removeFromQueue(itemId: UUID) async throws {
        // Cancel any pending retry
        retryCoordinator.cancelRetry(for: itemId)

        try await performQueueMutation {
            try queueStore.removeItem(id: itemId)
        }
    }

    /// Manually retry a failed item.
    /// - Parameter itemId: The ID of the item to retry
    func retryItem(itemId: UUID) async throws {
        try await performQueueMutation(startReason: .itemRetryRequested) {
            try queueStore.retryItem(id: itemId)
        }
    }

    /// Cancel a pending or processing item.
    /// - Parameter itemId: The ID of the item to cancel
    func cancelItem(itemId: UUID) async throws {
        // Cancel any pending retry
        retryCoordinator.cancelRetry(for: itemId)

        try await performQueueMutation {
            try queueStore.cancelItem(id: itemId)
        }
    }

    /// Clean up old completed/cancelled items.
    /// Removes items older than the retention period.
    func cleanupOldItems() async throws {
        try await performQueueMutation {
            try queueStore.cleanupOldItems()
        }
    }

    // MARK: - Stats

    /// Get current queue statistics.
    var stats: QueueStats {
        statsReporter.stats
    }

    /// Publisher for queue statistics updates.
    nonisolated(unsafe) var statsPublisher: AnyPublisher<QueueStats, Never> {
        statsReporter.publisher
    }

    /// Update queue statistics from database.
    private func updateStats() async {
        let newStats = (try? queueStore.stats(isProcessing: isProcessing)) ?? QueueStats(isProcessing: isProcessing)

        statsReporter.publish(newStats)
    }

    private func performQueueMutation<Value>(
        startReason: CaptureQueueProcessingStartReason? = nil,
        _ mutation: () throws -> Value
    ) async throws -> Value {
        let value = try mutation()

        await updateStats()

        if let startReason, await shouldStartProcessing(reason: startReason) {
            await startProcessing()
        }

        return value
    }

    // MARK: - Processing

    /// Start processing pending items.
    private func startProcessing() async {
        guard !isProcessing else { return }

        guard await networkMonitor.isConnected else { return }

        isProcessing = true
        await updateStats()

        processingTask = Task {
            await processQueue()
        }

        await processingTask?.value

        isProcessing = false
        await updateStats()
    }

    /// Process all pending items in the queue.
    private func processQueue() async {
        while !Task.isCancelled {
            // Check network before each batch
            let isConnected = await networkMonitor.isConnected
            guard isConnected else { break }

            // Fetch next pending item
            guard let itemID = await fetchNextPendingItemID() else {
                break  // No more items
            }

            await processItem(itemID: itemID)
        }
    }

    /// Fetch the next pending item ID to process.
    private func fetchNextPendingItemID() async -> UUID? {
        try? queueStore.nextPendingItemID()
    }

    /// Process a single queue item.
    private func processItem(itemID: UUID) async {
        let outcome = await itemProcessor.process(itemId: itemID) {
            await updateStats()
        }

        if let retryRequest = outcome.retryRequest {
            scheduleRetry(
                for: retryRequest.itemId,
                retryCount: retryRequest.retryCount
            )
        }
    }

    /// Schedule a delayed retry for a failed item.
    private func scheduleRetry(for itemId: UUID, retryCount: Int) {
        retryCoordinator.scheduleRetry(
            itemId: itemId,
            retryCount: retryCount,
            shouldRetry: {
                await self.shouldRetryScheduledItem(itemId: itemId)
            },
            retry: {
                await self.processItem(itemID: itemId)
            }
        )
    }

    private func shouldRetryScheduledItem(itemId: UUID) async -> Bool {
        guard await shouldStartProcessing(reason: .retryDelayElapsed) else {
            return false
        }

        return (try? queueStore.canRetryItem(id: itemId)) == true
    }

    private func shouldStartProcessing(reason: CaptureQueueProcessingStartReason) async -> Bool {
        let isConnected = await networkMonitor.isConnected
        return CaptureQueueProcessingStartPolicy.shouldStartProcessing(
            reason: reason,
            isConnected: isConnected,
            isAutoProcessEnabled: isAutoProcessEnabled
        )
    }

    // MARK: - Network Observation

    /// Start observing network connectivity changes.
    private func startNetworkObservation() async {
        let observer = CaptureQueueNetworkObserver(
            networkMonitor: networkMonitor,
            poller: networkPoller
        )

        networkObservation = Task { @MainActor in
            await observer.run(
                shouldAutoProcess: { await self.isAutoProcessEnabled },
                startProcessing: { await self.startProcessing() }
            )
        }
    }
}
