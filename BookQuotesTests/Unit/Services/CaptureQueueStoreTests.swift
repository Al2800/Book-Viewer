import SwiftData
import UIKit
import XCTest

@testable import BookQuotes

@MainActor
final class CaptureQueueStoreTests: SwiftDataTestCase {
    func testEnqueueStoresImageThumbnailPriorityAndStats() async throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let store = CaptureQueueStore(modelContainer: modelContainer)
        let item = try store.enqueue(
            image: testImage(fill: .white),
            book: book,
            priority: 7
        )

        XCTAssertEqual(item.priority, 7)
        XCTAssertEqual(item.status, .pending)
        XCTAssertNotNil(item.thumbnailData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.fullImagePath.path))

        let stats = try store.stats(isProcessing: false)
        XCTAssertEqual(stats.pendingCount, 1)
        XCTAssertEqual(stats.totalActive, 1)
        XCTAssertEqual(try store.nextPendingItemID(), item.id)
    }

    func testRetryCancelAndRemovePreserveQueueMutationBehavior() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(book: book, imagePath: "queued.jpg")
        item.status = .failed
        item.retryCount = 1
        item.lastError = "Transient failure"
        modelContext.insert(item)
        try modelContext.save()

        let store = CaptureQueueStore(modelContainer: modelContainer)

        try store.retryItem(id: item.id)
        var persisted = try XCTUnwrap(fetchItem(id: item.id))
        XCTAssertEqual(persisted.status, .pending)
        XCTAssertNil(persisted.lastError)

        try store.cancelItem(id: item.id)
        persisted = try XCTUnwrap(fetchItem(id: item.id))
        XCTAssertEqual(persisted.status, .cancelled)

        try store.removeItem(id: item.id)
        let remaining = try ModelContext(modelContainer).fetch(FetchDescriptor<CaptureQueueItem>())
        XCTAssertTrue(remaining.isEmpty)
    }

    func testRecoverInterruptedItemsMakesLegacyProcessingWorkRetryable() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let item = CaptureQueueItem(book: book, imagePath: "interrupted.jpg")
        item.markProcessing()
        modelContext.insert(item)
        try modelContext.save()

        let store = CaptureQueueStore(modelContainer: modelContainer)
        try store.recoverInterruptedItems()

        let persisted = try XCTUnwrap(fetchItem(id: item.id))
        XCTAssertEqual(persisted.status, .pending)
        XCTAssertNil(persisted.lastError)
    }

    func testProcessorReusesExistingLegacyQuoteAndDoesNotReextractCompletedItem() async throws {
        let book = Book(title: "Legacy Capture Book", author: "Reader")
        let savedQuote = Quote(
            text: "A saved passage must not be inserted a second time.",
            book: book
        )
        let imagePath = try XCTUnwrap(CaptureQueueItem.saveImage(testImage(fill: .white)))
        let item = CaptureQueueItem(book: book, imagePath: imagePath)

        modelContext.insert(book)
        modelContext.insert(savedQuote)
        modelContext.insert(item)
        try modelContext.save()

        let extractor = FixedQueueQuoteExtractor(result: QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "A saved passage must never be inserted a second time.",
                    pageNumber: 17,
                    marginNote: nil,
                    markingType: "underline",
                    confidence: 0.96
                )
            ],
            pageNumber: 17,
            processingNotes: "legacy queue retry"
        ))
        let processor = CaptureQueueItemProcessor(
            modelContainer: modelContainer,
            quoteExtractor: extractor
        )

        let firstOutcome = await processor.process(itemId: item.id, onStateChanged: {})
        guard case .completed = firstOutcome else {
            return XCTFail("Expected legacy queue processing to complete")
        }

        let persistedItem = try XCTUnwrap(fetchItem(id: item.id))
        let quotes = try fetchQuotes()
        XCTAssertEqual(quotes.count, 1)
        XCTAssertEqual(persistedItem.status, .completed)
        XCTAssertEqual(persistedItem.extractedQuotes?.map(\.id), [savedQuote.id])
        XCTAssertTrue(persistedItem.imagePath.isEmpty)
        XCTAssertEqual(extractor.callCount, 1)

        let secondOutcome = await processor.process(itemId: item.id, onStateChanged: {})
        guard case .completed = secondOutcome else {
            return XCTFail("Expected completed queue item to remain complete")
        }

        XCTAssertEqual(try fetchQuotes().count, 1)
        XCTAssertEqual(extractor.callCount, 1)
    }

    func testProcessorCompletesLegacyItemWithStoredQuotesWithoutReextracting() async throws {
        let book = Book(title: "Legacy Capture Book", author: "Reader")
        let savedQuote = Quote(
            text: "A legacy queue record already has this resolved passage.",
            book: book
        )
        let imagePath = try XCTUnwrap(CaptureQueueItem.saveImage(testImage(fill: .white)))
        let item = CaptureQueueItem(book: book, imagePath: imagePath)
        item.status = .failed
        item.extractedQuotes = [savedQuote]

        modelContext.insert(book)
        modelContext.insert(savedQuote)
        modelContext.insert(item)
        try modelContext.save()

        let extractor = FixedQueueQuoteExtractor(result: QuoteExtractionResult(
            quotes: [],
            pageNumber: nil,
            processingNotes: "should not run"
        ))
        let processor = CaptureQueueItemProcessor(
            modelContainer: modelContainer,
            quoteExtractor: extractor
        )

        let outcome = await processor.process(itemId: item.id, onStateChanged: {})
        guard case .completed = outcome else {
            return XCTFail("Expected the resolved legacy queue item to complete")
        }

        let persistedItem = try XCTUnwrap(fetchItem(id: item.id))
        XCTAssertEqual(persistedItem.status, .completed)
        XCTAssertEqual(persistedItem.extractedQuotes?.map(\.id), [savedQuote.id])
        XCTAssertTrue(persistedItem.imagePath.isEmpty)
        XCTAssertEqual(extractor.callCount, 0)
    }

    func testProcessorDeduplicatesRepeatedLegacyExtractionResults() async throws {
        let book = Book(title: "Legacy Capture Book", author: "Reader")
        let imagePath = try XCTUnwrap(CaptureQueueItem.saveImage(testImage(fill: .white)))
        let item = CaptureQueueItem(book: book, imagePath: imagePath)

        modelContext.insert(book)
        modelContext.insert(item)
        try modelContext.save()

        let extractor = FixedQueueQuoteExtractor(result: QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "A repeated passage returned by the extractor.",
                    pageNumber: 9,
                    marginNote: nil,
                    markingType: "underline",
                    confidence: 0.92
                ),
                ExtractedQuoteData(
                    text: "  a repeated passage returned by the extractor.  ",
                    pageNumber: 9,
                    marginNote: nil,
                    markingType: "highlight",
                    confidence: 0.88
                ),
                ExtractedQuoteData(
                    text: "A distinct passage that should be retained.",
                    pageNumber: 10,
                    marginNote: nil,
                    markingType: "bracket",
                    confidence: 0.91
                )
            ],
            pageNumber: 9,
            processingNotes: "legacy queue retry"
        ))
        let processor = CaptureQueueItemProcessor(
            modelContainer: modelContainer,
            quoteExtractor: extractor
        )

        let outcome = await processor.process(itemId: item.id, onStateChanged: {})
        guard case .completed = outcome else {
            return XCTFail("Expected legacy queue processing to complete")
        }

        let persistedItem = try XCTUnwrap(fetchItem(id: item.id))
        let quotes = try fetchQuotes()
        XCTAssertEqual(quotes.count, 2)
        XCTAssertEqual(persistedItem.extractedQuotes?.count, 2)
        XCTAssertEqual(extractor.callCount, 1)
    }

    private func fetchItem(id itemId: UUID) throws -> CaptureQueueItem? {
        let context = ModelContext(modelContainer)
        return try context.fetch(CaptureQueueFetch.itemDescriptor(id: itemId)).first
    }

    private func fetchQuotes() throws -> [Quote] {
        try ModelContext(modelContainer).fetch(FetchDescriptor<Quote>())
    }

    private func testImage(fill: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 180))
        return renderer.image { context in
            fill.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 120, height: 180))
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(x: 20, y: 44, width: 80, height: 8))
        }
    }
}

private final class FixedQueueQuoteExtractor: QuoteExtracting {
    private let result: QuoteExtractionResult
    private(set) var callCount = 0

    init(result: QuoteExtractionResult) {
        self.result = result
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt]
    ) async throws -> QuoteExtractionResult {
        callCount += 1
        return result
    }
}
