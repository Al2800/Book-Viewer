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

    private let modelContainer: ModelContainer
    private let geminiService: GeminiService
    private let networkMonitor: NetworkMonitor

    // MARK: - Configuration

    /// Key for the auto-process queue preference
    private static let autoProcessQueueKey = "autoProcessQueue"

    /// Whether automatic queue processing is enabled (defaults to true)
    nonisolated private var isAutoProcessEnabled: Bool {
        // Default to true if not set (maintains existing behavior)
        if UserDefaults.standard.object(forKey: Self.autoProcessQueueKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: Self.autoProcessQueueKey)
    }

    /// Exponential backoff delays in seconds for retries
    private let retryDelays: [TimeInterval] = [5, 30, 120]

    /// Maximum concurrent processing tasks
    private let maxConcurrentTasks = 2

    // MARK: - State

    private var isProcessing = false
    private var processingTask: Task<Void, Never>?
    private var networkObservation: Task<Void, Never>?
    private var pendingRetries: [UUID: Task<Void, Never>] = [:]

    /// Published queue statistics for UI binding
    nonisolated(unsafe) private let statsSubject = CurrentValueSubject<QueueStats, Never>(QueueStats())

    // MARK: - Initialization

    init(
        modelContainer: ModelContainer,
        geminiService: GeminiService,
        networkMonitor: NetworkMonitor
    ) {
        self.modelContainer = modelContainer
        self.geminiService = geminiService
        self.networkMonitor = networkMonitor
    }

    // MARK: - Lifecycle

    /// Start monitoring network and processing queue.
    /// Call this when the app becomes active.
    func start() async {
        // Start network observation
        await startNetworkObservation()

        // Initial stats update
        await updateStats()

        // Auto-process only if enabled in Settings
        guard isAutoProcessEnabled else { return }

        // Process if already online
        if await networkMonitor.isConnected {
            await startProcessing()
        }
    }

    /// Manually trigger queue processing.
    /// Use this when auto-process is disabled but user wants to process now.
    func processNow() async {
        if await networkMonitor.isConnected {
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

        // Cancel all pending retries
        for (_, task) in pendingRetries {
            task.cancel()
        }
        pendingRetries.removeAll()
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
        // Save image to disk
        guard let imagePath = CaptureQueueItem.saveImage(image) else {
            throw QueueError.imageStorageFailed
        }

        // Generate thumbnail
        let thumbnailData = CaptureQueueItem.generateThumbnail(from: image)

        // Create context for this operation
        let context = ModelContext(modelContainer)

        // Fetch the book in this context
        let bookId = book.id
        let bookDescriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.id == bookId }
        )
        guard let contextBook = try context.fetch(bookDescriptor).first else {
            throw QueueError.bookNotFound
        }

        // Create queue item
        let item = CaptureQueueItem(
            book: contextBook,
            imagePath: imagePath,
            thumbnailData: thumbnailData,
            priority: priority
        )
        context.insert(item)
        try context.save()

        // Update stats
        await updateStats()

        // Trigger processing if online and auto-process is enabled
        if await networkMonitor.isConnected && isAutoProcessEnabled {
            await startProcessing()
        }

        return item
    }

    /// Remove an item from the queue and delete its image file.
    /// - Parameter itemId: The ID of the item to remove
    func removeFromQueue(itemId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { $0.id == itemId }
        )

        guard let item = try context.fetch(descriptor).first else {
            return
        }

        // Cancel any pending retry
        pendingRetries[itemId]?.cancel()
        pendingRetries.removeValue(forKey: itemId)

        // Delete image file
        item.deleteImageFile()

        // Delete from database
        context.delete(item)
        try context.save()

        await updateStats()
    }

    /// Manually retry a failed item.
    /// - Parameter itemId: The ID of the item to retry
    func retryItem(itemId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { $0.id == itemId }
        )

        guard let item = try context.fetch(descriptor).first else {
            throw QueueError.itemNotFound
        }

        item.resetForRetry()
        try context.save()

        await updateStats()

        // Trigger processing
        if await networkMonitor.isConnected {
            await startProcessing()
        }
    }

    /// Cancel a pending or processing item.
    /// - Parameter itemId: The ID of the item to cancel
    func cancelItem(itemId: UUID) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { $0.id == itemId }
        )

        guard let item = try context.fetch(descriptor).first else {
            return
        }

        // Cancel any pending retry
        pendingRetries[itemId]?.cancel()
        pendingRetries.removeValue(forKey: itemId)

        item.cancel()
        try context.save()

        await updateStats()
    }

    /// Clean up old completed/cancelled items.
    /// Removes items older than the retention period.
    func cleanupOldItems() async throws {
        let context = ModelContext(modelContainer)
        let items = try context.fetch(CaptureQueueItem.cleanupDescriptor)

        for item in items {
            item.deleteImageFile()
            context.delete(item)
        }

        try context.save()
        await updateStats()
    }

    // MARK: - Stats

    /// Get current queue statistics.
    var stats: QueueStats {
        statsSubject.value
    }

    /// Publisher for queue statistics updates.
    nonisolated(unsafe) var statsPublisher: AnyPublisher<QueueStats, Never> {
        statsSubject.eraseToAnyPublisher()
    }

    /// Update queue statistics from database.
    private func updateStats() async {
        let context = ModelContext(modelContainer)

        var pendingCount = 0
        var processingCount = 0
        var failedCount = 0
        var completedCount = 0

        // Count by status
        let allDescriptor = FetchDescriptor<CaptureQueueItem>()
        if let items = try? context.fetch(allDescriptor) {
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
        }

        let newStats = QueueStats(
            pendingCount: pendingCount,
            processingCount: processingCount,
            failedCount: failedCount,
            completedCount: completedCount,
            isProcessing: isProcessing
        )

        statsSubject.send(newStats)
    }

    // MARK: - Processing

    /// Start processing pending items.
    private func startProcessing() async {
        guard !isProcessing else { return }

        let isConnected = await networkMonitor.isConnected
        guard isConnected else { return }

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
            guard let item = await fetchNextPendingItem() else {
                break  // No more items
            }

            await processItem(item)
        }
    }

    /// Fetch the next pending item to process.
    private func fetchNextPendingItem() async -> CaptureQueueItem? {
        let context = ModelContext(modelContainer)
        var descriptor = CaptureQueueItem.pendingDescriptor
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }

    /// Process a single queue item.
    private func processItem(_ item: CaptureQueueItem) async {
        let context = ModelContext(modelContainer)

        // Fetch item in this context
        let itemId = item.id
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { $0.id == itemId }
        )

        guard let contextItem = try? context.fetch(descriptor).first else {
            return
        }

        // Mark as processing
        contextItem.markProcessing()
        try? context.save()
        await updateStats()

        do {
            // Load image
            guard let image = contextItem.loadFullImage() else {
                throw QueueError.imageLoadFailed
            }

            // Fetch marking definitions for the extraction prompt
            let markingDescriptor = FetchDescriptor<MarkingDefinition>(
                predicate: #Predicate<MarkingDefinition> { $0.isEnabled }
            )
            let markings = (try? context.fetch(markingDescriptor)) ?? []

            // Call Gemini API for extraction
            let result = try await geminiService.extractQuotes(from: image, markings: markings)

            // Create Quote objects from extracted data
            guard let book = contextItem.book else {
                throw QueueError.bookNotFound
            }

            var quotes: [Quote] = []
            for extractedQuote in result.quotes {
                let extractedData = extractedQuote.toExtractedQuote()
                let quote = Quote(
                    text: extractedQuote.text,
                    book: book,
                    markingType: extractedData.markingType
                )
                quote.pageNumber = extractedQuote.pageNumber
                quote.marginNote = extractedQuote.marginNote
                quote.confidence = extractedQuote.confidence

                context.insert(quote)
                quotes.append(quote)
            }

            // Mark completed
            contextItem.markCompleted(quotes: quotes)
            try context.save()

            await updateStats()

        } catch {
            // Handle failure
            contextItem.markFailed(error: error)
            try? context.save()
            await updateStats()

            // Schedule retry if applicable
            if contextItem.canRetry {
                await scheduleRetry(for: contextItem.id, retryCount: contextItem.retryCount)
            }
        }
    }

    /// Schedule a delayed retry for a failed item.
    private func scheduleRetry(for itemId: UUID, retryCount: Int) async {
        // Cancel any existing retry for this item
        pendingRetries[itemId]?.cancel()

        let delayIndex = max(0, min(retryCount - 1, retryDelays.count - 1))
        let delay = retryDelays[delayIndex]

        let task = Task {
            try? await Task.sleep(for: .seconds(delay))

            guard !Task.isCancelled else { return }

            // Check if still connected
            let isConnected = await networkMonitor.isConnected
            guard isConnected else { return }

            // Fetch and reprocess
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<CaptureQueueItem>(
                predicate: #Predicate<CaptureQueueItem> { $0.id == itemId }
            )

            if let item = try? context.fetch(descriptor).first,
               item.canRetry {
                await processItem(item)
            }
        }

        pendingRetries[itemId] = task
    }

    // MARK: - Network Observation

    /// Start observing network connectivity changes.
    private func startNetworkObservation() async {
        // Ensure monitoring is active
        await networkMonitor.startMonitoring()

        networkObservation = Task { @MainActor in
            // Poll for network changes (NetworkMonitor uses @Observable)
            var wasConnected = networkMonitor.isConnected

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                let isNowConnected = networkMonitor.isConnected

                // Connection restored - only auto-process if enabled
                if !wasConnected && isNowConnected && self.isAutoProcessEnabled {
                    await self.startProcessing()
                }

                wasConnected = isNowConnected
            }
        }
    }
}

// MARK: - QueueStats

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

// MARK: - QueueError

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

// MARK: - Shared Instance

extension CaptureQueueManager {
    /// Shared instance for app-wide queue management.
    /// Initialize in your App's init with the appropriate dependencies.
    @MainActor
    static var shared: CaptureQueueManager?

    /// Initialize the shared instance.
    /// Call this early in app lifecycle.
    @MainActor
    static func initialize(
        modelContainer: ModelContainer,
        geminiService: GeminiService,
        networkMonitor: NetworkMonitor
    ) {
        shared = CaptureQueueManager(
            modelContainer: modelContainer,
            geminiService: geminiService,
            networkMonitor: networkMonitor
        )
    }
}
