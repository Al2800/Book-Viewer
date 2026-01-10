import XCTest

@testable import BookQuotes

/// Performance tests for search functionality.
/// Measures response times across different dataset sizes to ensure
/// search remains fast as the library grows.
@MainActor
final class SearchPerformanceTests: FTS5TestCase {

    // MARK: - Thresholds

    /// Maximum acceptable indexing time per 1000 quotes (ms)
    private let indexing1KThresholdMs: Double = 5000

    /// Maximum acceptable indexing time for 10K quotes (ms)
    private let indexing10KThresholdMs: Double = 30000

    /// Maximum acceptable average search time (ms)
    private let searchAverageThresholdMs: Double = 50

    /// Maximum acceptable P95 search time (ms)
    private let searchP95ThresholdMs: Double = 100

    /// Maximum acceptable P99 search time (ms)
    private let searchP99ThresholdMs: Double = 200

    // MARK: - Indexing Performance Tests

    func testIndexing_1000Quotes_UnderThreshold() async throws {
        logger.step(1, "Generating 1000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 10, quotesPerBook: 100)

        logger.step(2, "Measuring indexing time")
        let startTime = CFAbsoluteTimeGetCurrent()

        for book in books {
            try await indexBook(book)
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        logger.metric("indexing_1000_quotes_ms", value: elapsed)
        logger.info("Indexed 1000 quotes in \(Int(elapsed))ms")

        XCTAssertLessThan(
            elapsed, indexing1KThresholdMs,
            "Indexing 1000 quotes took \(Int(elapsed))ms, exceeds threshold of \(Int(indexing1KThresholdMs))ms"
        )

        logger.success("Indexing performance acceptable")
    }

    func testIndexing_5000Quotes_UnderThreshold() async throws {
        logger.step(1, "Generating 5000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 50, quotesPerBook: 100)

        logger.step(2, "Measuring indexing time")
        let startTime = CFAbsoluteTimeGetCurrent()

        for book in books {
            try await indexBook(book)
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        logger.metric("indexing_5000_quotes_ms", value: elapsed)
        logger.info("Indexed 5000 quotes in \(Int(elapsed))ms")

        // Allow 5x the 1K threshold for 5x the data
        let threshold = indexing1KThresholdMs * 5
        XCTAssertLessThan(
            elapsed, threshold,
            "Indexing 5000 quotes took \(Int(elapsed))ms, exceeds threshold of \(Int(threshold))ms"
        )

        logger.success("Indexing 5000 quotes performance acceptable")
    }

    func testIndexing_10000Quotes_UnderThreshold() async throws {
        logger.step(1, "Generating 10000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)

        logger.step(2, "Measuring indexing time")
        let startTime = CFAbsoluteTimeGetCurrent()

        for book in books {
            try await indexBook(book)
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        logger.metric("indexing_10000_quotes_ms", value: elapsed)
        logger.info("Indexed 10000 quotes in \(Int(elapsed))ms")

        XCTAssertLessThan(
            elapsed, indexing10KThresholdMs,
            "Indexing 10000 quotes took \(Int(elapsed))ms, exceeds threshold of \(Int(indexing10KThresholdMs))ms"
        )

        logger.success("Indexing 10000 quotes performance acceptable")
    }

    // MARK: - Query Performance Tests

    func testSearch_SingleWord_1000Quotes() async throws {
        logger.step(1, "Setting up 1000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 10, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring single-word search performance")
        let result = try await measureSearchPerformance(query: "happiness", iterations: 100)

        logger.metric("search_1k_avg_ms", value: result.averageMs)
        logger.metric("search_1k_p95_ms", value: result.p95Ms)
        logger.metric("search_1k_p99_ms", value: result.p99Ms)

        result.assertAverageUnder(searchAverageThresholdMs)
        result.assertP95Under(searchP95ThresholdMs)
        result.assertP99Under(searchP99ThresholdMs)

        logger.success("Search performance on 1K quotes acceptable")
    }

    func testSearch_SingleWord_5000Quotes() async throws {
        logger.step(1, "Setting up 5000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 50, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring single-word search performance")
        let result = try await measureSearchPerformance(query: "success", iterations: 100)

        logger.metric("search_5k_avg_ms", value: result.averageMs)
        logger.metric("search_5k_p95_ms", value: result.p95Ms)
        logger.metric("search_5k_p99_ms", value: result.p99Ms)

        // Allow slightly higher thresholds for larger dataset
        result.assertAverageUnder(searchAverageThresholdMs * 1.5)
        result.assertP95Under(searchP95ThresholdMs * 1.5)

        logger.success("Search performance on 5K quotes acceptable")
    }

    func testSearch_SingleWord_10000Quotes() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring single-word search performance")
        let result = try await measureSearchPerformance(query: "wisdom", iterations: 100)

        logger.metric("search_10k_avg_ms", value: result.averageMs)
        logger.metric("search_10k_p95_ms", value: result.p95Ms)
        logger.metric("search_10k_p99_ms", value: result.p99Ms)

        // Allow 2x thresholds for 10x the data
        result.assertAverageUnder(searchAverageThresholdMs * 2)
        result.assertP95Under(searchP95ThresholdMs * 2)

        logger.success("Search performance on 10K quotes acceptable")
    }

    // MARK: - Multi-Word Query Tests

    func testSearch_MultiWord_10000Quotes() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring multi-word search performance")
        let result = try await measureSearchPerformance(
            query: "happiness success growth",
            iterations: 100
        )

        logger.metric("search_multiword_avg_ms", value: result.averageMs)
        logger.metric("search_multiword_p95_ms", value: result.p95Ms)

        // Multi-word queries can be slightly slower
        result.assertAverageUnder(searchAverageThresholdMs * 3)

        logger.success("Multi-word search performance acceptable")
    }

    // MARK: - Prefix Search Tests

    func testSearch_Prefix_10000Quotes() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring prefix search performance")
        let result = try await measureSearchPerformance(query: "happ*", iterations: 100)

        logger.metric("search_prefix_avg_ms", value: result.averageMs)
        logger.metric("search_prefix_p95_ms", value: result.p95Ms)

        // Prefix searches may be slightly slower
        result.assertAverageUnder(searchAverageThresholdMs * 2)

        logger.success("Prefix search performance acceptable")
    }

    // MARK: - Scope Filter Tests

    func testSearch_BooksScope_10000Quotes() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring books-only search performance")
        var durations: [Double] = []

        for _ in 0..<100 {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await searchDatabase.search(query: "Book 5", scope: .books)
            durations.append(CFAbsoluteTimeGetCurrent() - start)
        }

        let result = SearchPerformanceResult(
            query: "Book 5",
            iterations: 100,
            durations: durations
        )

        logger.metric("search_books_scope_avg_ms", value: result.averageMs)

        result.assertAverageUnder(searchAverageThresholdMs)

        logger.success("Books scope search performance acceptable")
    }

    func testSearch_QuotesScope_10000Quotes() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring quotes-only search performance")
        var durations: [Double] = []

        for _ in 0..<100 {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await searchDatabase.search(query: "motivation", scope: .quotes)
            durations.append(CFAbsoluteTimeGetCurrent() - start)
        }

        let result = SearchPerformanceResult(
            query: "motivation",
            iterations: 100,
            durations: durations
        )

        logger.metric("search_quotes_scope_avg_ms", value: result.averageMs)

        result.assertAverageUnder(searchAverageThresholdMs)

        logger.success("Quotes scope search performance acceptable")
    }

    // MARK: - Concurrent Search Tests

    func testSearch_Concurrent_10000Quotes() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring concurrent search performance")
        let queries = ["happiness", "success", "growth", "wisdom", "focus"]

        let startTime = CFAbsoluteTimeGetCurrent()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for query in queries {
                group.addTask {
                    for _ in 0..<20 {
                        _ = try await self.searchDatabase.search(query: query, scope: .all)
                    }
                }
            }
            try await group.waitForAll()
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        logger.metric("concurrent_100_searches_ms", value: elapsed)
        logger.info("100 concurrent searches completed in \(Int(elapsed))ms")

        // 100 searches should complete in under 5 seconds
        XCTAssertLessThan(elapsed, 5000, "Concurrent searches took too long")

        logger.success("Concurrent search performance acceptable")
    }

    // MARK: - Index Rebuild Tests

    func testRebuildIndex_10000Quotes_UnderThreshold() async throws {
        logger.step(1, "Generating 10000 quotes")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)

        // Insert into model context first
        for book in books {
            modelContext.insert(book)
        }
        try modelContext.save()

        logger.step(2, "Measuring full index rebuild time")
        let startTime = CFAbsoluteTimeGetCurrent()

        try await searchDatabase.rebuildIndex(books: books)

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        logger.metric("rebuild_10k_quotes_ms", value: elapsed)
        logger.info("Rebuilt index for 10000 quotes in \(Int(elapsed))ms")

        // Rebuild should be comparable to initial indexing
        XCTAssertLessThan(
            elapsed, indexing10KThresholdMs * 1.2,
            "Index rebuild took too long"
        )

        logger.success("Index rebuild performance acceptable")
    }

    // MARK: - No Results Query Tests

    func testSearch_NoResults_Fast() async throws {
        logger.step(1, "Setting up 10000 quote index")
        let books = TestFixtures.largeBookCollection(bookCount: 100, quotesPerBook: 100)
        for book in books {
            try await indexBook(book)
        }

        logger.step(2, "Measuring no-results search performance")
        let result = try await measureSearchPerformance(
            query: "xyznonexistentterm123",
            iterations: 100
        )

        logger.metric("search_no_results_avg_ms", value: result.averageMs)

        // No-results queries should be as fast or faster
        result.assertAverageUnder(searchAverageThresholdMs)

        logger.success("No-results search performance acceptable")
    }
}
