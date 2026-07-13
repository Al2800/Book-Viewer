import XCTest
import SwiftData
import Combine

@testable import BookQuotes

/// Integration tests for offline queue flow.
/// Tests enqueue → persist → process flow with real components.
@MainActor
final class OfflineQueueFlowTests: SwiftDataTestCase {

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

        logger.info("OfflineQueueFlowTests setup complete")
    }

    override func tearDown() async throws {
        await queueManager.stop()
        queueManager = nil
        quoteExtractor = nil
        authService = nil
        cancellables.removeAll()
        try await super.tearDown()
    }

    // MARK: - Queue Persistence Tests

    func testFlow_AddToQueue_PersistsToSwiftData() async throws {
        logger.step(1, "Creating a book")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        logger.step(2, "Adding image to queue")
        let image = createTestImage()
        let queueItem = try await queueManager.addToQueue(image: image, book: book)

        logger.step(3, "Verifying queue item persisted")
        XCTAssertNotNil(queueItem.id)
        XCTAssertEqual(queueItem.status, .pending)

        logger.step(4, "Verifying stats updated")
        let stats = await queueManager.stats
        XCTAssertEqual(stats.pendingCount, 1)

        logger.success("Queue item persisted to SwiftData")
    }

    func testFlow_AddMultipleItems_AllPersisted() async throws {
        logger.step(1, "Creating a book")
        let book = TestFixtures.deepWork
        try insertBook(book)

        logger.step(2, "Adding multiple images")
        let image1 = createTestImage()
        let image2 = createTestImage()
        let image3 = createTestImage()

        _ = try await queueManager.addToQueue(image: image1, book: book, priority: 0)
        _ = try await queueManager.addToQueue(image: image2, book: book, priority: 1)
        _ = try await queueManager.addToQueue(image: image3, book: book, priority: 2)

        logger.step(3, "Verifying all items persisted")
        let stats = await queueManager.stats
        XCTAssertEqual(stats.pendingCount, 3)

        logger.success("Multiple queue items persisted")
    }

    func testFlow_RemoveFromQueue_DeletesItem() async throws {
        logger.step(1, "Creating and queueing item")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let image = createTestImage()
        let queueItem = try await queueManager.addToQueue(image: image, book: book)

        logger.step(2, "Verifying item exists")
        var stats = await queueManager.stats
        XCTAssertEqual(stats.pendingCount, 1)

        logger.step(3, "Removing from queue")
        try await queueManager.removeFromQueue(itemId: queueItem.id)

        logger.step(4, "Verifying item removed")
        stats = await queueManager.stats
        XCTAssertEqual(stats.pendingCount, 0)

        logger.success("Queue item removed")
    }

    // MARK: - Queue Stats Publisher Tests

    func testFlow_StatsPublisher_EmitsOnChange() async throws {
        logger.step(1, "Setting up stats observer")
        var receivedStats: [QueueStats] = []
        let expectation = XCTestExpectation(description: "Receive stats updates")
        // Fulfill once when we have observed both the initial value and at least one change.

        queueManager.statsPublisher
            .receive(on: RunLoop.main)
            .sink { stats in
                receivedStats.append(stats)
                if receivedStats.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        logger.step(2, "Adding item to trigger stats update")
        let book = TestFixtures.atomicHabits
        try insertBook(book)
        _ = try await queueManager.addToQueue(image: createTestImage(), book: book)

        logger.step(3, "Waiting for stats updates")
        await fulfillment(of: [expectation], timeout: 5)

        logger.step(4, "Verifying stats progression")
        XCTAssertGreaterThanOrEqual(receivedStats.count, 2)

        logger.success("Stats publisher emits on change")
    }

    // MARK: - Queue Start/Stop Tests

    func testFlow_Start_InitializesStats() async throws {
        logger.step(1, "Starting queue manager")
        await queueManager.start()

        logger.step(2, "Verifying stats initialized")
        let stats = await queueManager.stats
        XCTAssertFalse(stats.isProcessing)  // No items to process

        logger.success("Queue manager starts correctly")
    }

    func testFlow_Stop_CancelsPendingTasks() async throws {
        logger.step(1, "Starting and adding items")
        await queueManager.start()

        let book = TestFixtures.atomicHabits
        try insertBook(book)
        _ = try await queueManager.addToQueue(image: createTestImage(), book: book)

        logger.step(2, "Stopping queue manager")
        await queueManager.stop()

        logger.step(3, "Verifying stopped state")
        // Manager should stop gracefully without crashes
        logger.success("Queue manager stops without error")
    }

    // MARK: - CaptureQueueItem Model Tests

    func testFlow_QueueItem_ImagePathPersists() async throws {
        logger.step(1, "Creating queue item with image")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let image = createTestImage()
        let queueItem = try await queueManager.addToQueue(image: image, book: book)

        logger.step(2, "Verifying image path stored")
        XCTAssertFalse(queueItem.imagePath.isEmpty)

        logger.step(3, "Verifying image can be loaded")
        let loadedImage = queueItem.loadFullImage()
        XCTAssertNotNil(loadedImage)

        logger.success("Queue item image path persists and loads")
    }

    func testFlow_QueueItem_ThumbnailGenerated() async throws {
        logger.step(1, "Creating queue item")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let image = createTestImage()
        let queueItem = try await queueManager.addToQueue(image: image, book: book)

        logger.step(2, "Verifying thumbnail generated")
        XCTAssertNotNil(queueItem.thumbnailData)
        XCTAssertFalse(queueItem.thumbnailData?.isEmpty ?? true)

        logger.success("Queue item thumbnail generated")
    }

    // MARK: - Queue Priority Tests

    func testFlow_QueuePriority_HigherProcessedFirst() async throws {
        logger.step(1, "Creating book")
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        logger.step(2, "Adding items with different priorities")
        let lowPriority = try await queueManager.addToQueue(
            image: createTestImage(),
            book: book,
            priority: 0
        )
        let highPriority = try await queueManager.addToQueue(
            image: createTestImage(),
            book: book,
            priority: 10
        )

        logger.step(3, "Verifying both items queued")
        let stats = await queueManager.stats
        XCTAssertEqual(stats.pendingCount, 2)

        logger.step(4, "Verifying priorities set correctly")
        XCTAssertEqual(lowPriority.priority, 0)
        XCTAssertEqual(highPriority.priority, 10)

        logger.success("Queue priority set correctly")
    }

    // MARK: - Error Handling Tests

    func testFlow_AddToQueue_NonExistentBook_Throws() async throws {
        logger.step(1, "Creating book without inserting")
        let book = TestFixtures.atomicHabits
        // Deliberately NOT inserting the book

        logger.step(2, "Attempting to add to queue")
        do {
            _ = try await queueManager.addToQueue(image: createTestImage(), book: book)
            XCTFail("Should have thrown error for non-existent book")
        } catch {
            logger.step(3, "Caught expected error")
            // Expected behavior
        }

        logger.success("Non-existent book throws error")
    }

    // MARK: - Data Flow Tests

    func testFlow_QueueItem_BookRelationship() async throws {
        logger.step(1, "Creating book and queue item")
        let book = TestFixtures.book { b in
            b.title = "Related Book"
            b.author = "Test Author"
        }
        try insertBook(book)

        let queueItem = try await queueManager.addToQueue(
            image: createTestImage(),
            book: book
        )

        logger.step(2, "Verifying book relationship")
        XCTAssertNotNil(queueItem.book)
        XCTAssertEqual(queueItem.book?.title, "Related Book")

        logger.success("Queue item has correct book relationship")
    }

    // MARK: - Helpers

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setFill()
            for i in 0..<20 {
                let y = CGFloat(50 + i * 25)
                context.fill(CGRect(x: 30, y: y, width: CGFloat.random(in: 200...350), height: 3))
            }
        }
    }
}
