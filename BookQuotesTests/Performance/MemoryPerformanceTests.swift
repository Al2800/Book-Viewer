import XCTest

@testable import BookQuotes

/// Performance tests for memory usage and large dataset handling.
/// Measures memory footprint during operations to ensure efficiency.
@MainActor
final class MemoryPerformanceTests: SwiftDataTestCase {

    // MARK: - Memory Measurement Helpers

    private func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return info.resident_size
    }

    private func memoryMB() -> Double {
        Double(currentMemoryUsage()) / 1024 / 1024
    }

    private func forceGC() async {
        // Give ARC time to release
        await Task.yield()
        // Additional yield for cleanup
        try? await Task.sleep(for: .milliseconds(100))
    }

    // MARK: - Thresholds

    /// Maximum baseline memory usage (MB)
    private let baselineMemoryThresholdMB: Double = 50

    /// Maximum memory increase per 1000 quotes (MB)
    private let memoryPer1KQuotesMB: Double = 20

    /// Maximum total memory for 10K quotes (MB)
    private let maxMemory10KQuotesMB: Double = 200

    // MARK: - Base Memory Tests

    func testBaseline_EmptyApp_MemoryUsage() async throws {
        logger.step(1, "Measuring baseline memory")

        let baseline = memoryMB()
        logger.metric("baseline_memory_mb", value: baseline)

        XCTAssertLessThan(
            baseline, baselineMemoryThresholdMB,
            "Baseline memory \(String(format: "%.1f", baseline))MB exceeds threshold"
        )

        logger.success("Baseline memory: \(String(format: "%.1f", baseline))MB")
    }

    // MARK: - Data Loading Memory Tests

    func testMemory_Load1000Quotes_Acceptable() async throws {
        let baseline = memoryMB()
        logger.info("Baseline: \(String(format: "%.1f", baseline))MB")

        logger.step(1, "Loading 1000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 10, quotesPerBook: 100)
        insertBooks(books)

        await forceGC()
        let afterLoad = memoryMB()
        let increase = afterLoad - baseline

        logger.metric("memory_1000_quotes_mb", value: afterLoad)
        logger.metric("memory_increase_1000_quotes_mb", value: increase)

        XCTAssertLessThan(
            increase, memoryPer1KQuotesMB,
            "Memory increase \(String(format: "%.1f", increase))MB too high for 1000 quotes"
        )

        logger.success("1000 quotes loaded with \(String(format: "%.1f", increase))MB increase")
    }

    func testMemory_Load5000Quotes_Acceptable() async throws {
        let baseline = memoryMB()
        logger.info("Baseline: \(String(format: "%.1f", baseline))MB")

        logger.step(1, "Loading 5000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 50, quotesPerBook: 100)
        insertBooks(books)

        await forceGC()
        let afterLoad = memoryMB()
        let increase = afterLoad - baseline

        logger.metric("memory_5000_quotes_mb", value: afterLoad)
        logger.metric("memory_increase_5000_quotes_mb", value: increase)

        // Allow 5x the per-1K threshold
        XCTAssertLessThan(
            increase, memoryPer1KQuotesMB * 5,
            "Memory increase \(String(format: "%.1f", increase))MB too high for 5000 quotes"
        )

        logger.success("5000 quotes loaded with \(String(format: "%.1f", increase))MB increase")
    }

    func testMemory_Load10000Quotes_Acceptable() async throws {
        let baseline = memoryMB()
        logger.info("Baseline: \(String(format: "%.1f", baseline))MB")

        logger.step(1, "Loading 10000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        insertBooks(books)

        await forceGC()
        let afterLoad = memoryMB()

        logger.metric("memory_10000_quotes_mb", value: afterLoad)
        logger.metric("memory_total_10000_quotes_mb", value: afterLoad)

        XCTAssertLessThan(
            afterLoad, maxMemory10KQuotesMB,
            "Total memory \(String(format: "%.1f", afterLoad))MB exceeds threshold for 10K quotes"
        )

        logger.success("10000 quotes loaded, total memory: \(String(format: "%.1f", afterLoad))MB")
    }

    // MARK: - Memory Release Tests

    func testMemory_DeleteBooks_Releases() async throws {
        let baseline = memoryMB()

        logger.step(1, "Loading 1000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 10, quotesPerBook: 100)
        insertBooks(books)

        await forceGC()
        let afterLoad = memoryMB()
        let loadIncrease = afterLoad - baseline

        logger.step(2, "Deleting all books")
        for book in books {
            modelContext.delete(book)
        }
        try modelContext.save()

        await forceGC()
        let afterDelete = memoryMB()

        logger.metric("memory_after_load_mb", value: afterLoad)
        logger.metric("memory_after_delete_mb", value: afterDelete)

        // Memory should drop significantly after deletion
        let recovered = afterLoad - afterDelete
        let recoveryPercent = (recovered / loadIncrease) * 100

        logger.info("Recovered \(String(format: "%.1f", recovered))MB (\(String(format: "%.0f", recoveryPercent))%)")

        // Should recover at least 50% of loaded memory
        XCTAssertGreaterThan(
            recoveryPercent, 50,
            "Only recovered \(String(format: "%.0f", recoveryPercent))% of memory after deletion"
        )

        logger.success("Memory properly released after deletion")
    }

    // MARK: - Batch Processing Memory Tests

    func testMemory_BatchInsert_NoAccumulation() async throws {
        let baseline = memoryMB()

        logger.step(1, "Inserting books in batches")

        var maxMemory = baseline
        let batchSize = 10
        let totalBatches = 10

        for batch in 0..<totalBatches {
            let books = TestFixtures.largeBookCollection(bookCount: batchSize, quotesPerBook: 50)
            insertBooks(books)

            await forceGC()
            let current = memoryMB()
            maxMemory = max(maxMemory, current)

            logger.debug("Batch \(batch + 1): \(String(format: "%.1f", current))MB")
        }

        let totalIncrease = maxMemory - baseline
        let perBatchIncrease = totalIncrease / Double(totalBatches)

        logger.metric("batch_insert_max_memory_mb", value: maxMemory)
        logger.metric("batch_insert_per_batch_mb", value: perBatchIncrease)

        // Memory should scale linearly, not accumulate excessively
        let expectedMax = baseline + (memoryPer1KQuotesMB * 5) // 5000 quotes total
        XCTAssertLessThan(
            maxMemory, expectedMax,
            "Memory accumulated excessively during batch inserts"
        )

        logger.success("Batch insert memory acceptable")
    }

    // MARK: - Query Memory Tests

    func testMemory_RepeatedQueries_NoLeak() async throws {
        logger.step(1, "Setting up test data")
        let books = TestFixtures.largeBookCollection(bookCount: 10, quotesPerBook: 100)
        insertBooks(books)

        await forceGC()
        let baseline = memoryMB()

        logger.step(2, "Running 1000 queries")
        for i in 0..<1000 {
            _ = try modelContext.fetch(FetchDescriptor<Quote>())
            if i % 100 == 0 {
                await forceGC()
            }
        }

        await forceGC()
        let afterQueries = memoryMB()
        let increase = afterQueries - baseline

        logger.metric("memory_after_1000_queries_mb", value: afterQueries)
        logger.metric("memory_increase_queries_mb", value: increase)

        // Queries should not significantly increase memory
        XCTAssertLessThan(
            increase, 10,
            "Memory increased by \(String(format: "%.1f", increase))MB after queries - possible leak"
        )

        logger.success("No memory leak detected from repeated queries")
    }

    // MARK: - Image Data Memory Tests

    func testMemory_BookCovers_Managed() async throws {
        let baseline = memoryMB()

        logger.step(1, "Creating books with cover images")
        var books: [Book] = []
        for i in 0..<50 {
            let book = TestFixtures.book { builder in
                builder.title = "Book \(i)"
                builder.coverThumbnailData = TestFixtures.TestImages.bookCover
            }
            books.append(book)
        }
        insertBooks(books)

        await forceGC()
        let afterLoad = memoryMB()
        let increase = afterLoad - baseline

        logger.metric("memory_50_covers_mb", value: afterLoad)
        logger.metric("memory_increase_covers_mb", value: increase)

        // 50 covers (each ~50KB) should add less than 10MB
        XCTAssertLessThan(
            increase, 10,
            "Memory for 50 book covers too high"
        )

        logger.success("Book cover memory managed properly")
    }

    // MARK: - Helper Methods

    private func insertBooks(_ books: [Book]) {
        for book in books {
            modelContext.insert(book)
        }
        try? modelContext.save()
    }
}
