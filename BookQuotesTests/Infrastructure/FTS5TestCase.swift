import XCTest
import SQLite3

@testable import BookQuotes

// MARK: - FTS5TestCase

/// Base test case for FTS5 search testing.
/// Provides temporary database and cleanup.
///
/// Example usage:
/// ```swift
/// final class SearchDatabaseTests: FTS5TestCase {
///     func testExactMatchSearch() async throws {
///         logger.step(1, "Creating test data")
///         let book = TestFixtures.atomicHabits
///         let quote = TestFixtures.quote { q in
///             q.text = "Happiness is not about achieving your goals"
///             q.book = book
///         }
///
///         try insertBook(book)
///         modelContext.insert(quote)
///         try modelContext.save()
///
///         try await indexBook(book)
///         try await assertSearchCount("happiness", expectedQuotes: 1)
///     }
/// }
/// ```
@MainActor
class FTS5TestCase: SwiftDataTestCase {

    // MARK: - Properties

    /// Search database instance for tests.
    var searchDatabase: SearchDatabase!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        logger.info("Setting up FTS5 test environment")

        do {
            // Use in-memory DB to avoid filesystem side effects (and to respect the repo rule
            // that agents must not delete files/directories without explicit approval).
            searchDatabase = try SearchDatabase(inMemory: true)
            logger.success("FTS5 database created", context: [
                "path": ":memory:"
            ])
        } catch {
            logger.error("Failed to create FTS5 database", error: error)
            throw error
        }
    }

    override func tearDown() async throws {
        logger.info("Tearing down FTS5 test environment")

        // Close database connection by releasing reference
        searchDatabase = nil

        try await super.tearDown()
    }

    // MARK: - Index Helpers

    /// Index a book and all its quotes
    func indexBook(_ book: Book) async throws {
        try await searchDatabase.indexBook(book)
        for quote in book.quotes {
            try await searchDatabase.indexQuote(quote, book: book)
        }
        logger.debug("Indexed book", context: [
            "title": book.title,
            "quotes": "\(book.quotes.count)"
        ])
    }

    /// Index a single quote
    func indexQuote(_ quote: Quote, book: Book) async throws {
        try await searchDatabase.indexQuote(quote, book: book)
        logger.debug("Indexed quote", context: [
            "text": String(quote.text.prefix(40)),
            "book": book.title
        ])
    }

    /// Index multiple books
    func indexBooks(_ books: [Book]) async throws {
        for book in books {
            try await indexBook(book)
        }
        logger.debug("Indexed all books", context: ["count": "\(books.count)"])
    }

    /// Rebuild entire index from provided books
    func rebuildIndex(books: [Book]) async throws {
        try await searchDatabase.rebuildIndex(books: books)
        let quoteCount = books.reduce(0) { $0 + $1.quotes.count }
        logger.debug("Rebuilt search index", context: [
            "books": "\(books.count)",
            "quotes": "\(quoteCount)"
        ])
    }

    // MARK: - Search Helpers

    /// Execute search and return results
    func search(
        _ query: String,
        scope: SearchScope = .all
    ) async throws -> SearchResults {
        let start = CFAbsoluteTimeGetCurrent()
        let results = try await searchDatabase.search(query: query, scope: scope)
        let duration = CFAbsoluteTimeGetCurrent() - start

        logger.debug("Search executed", context: [
            "query": query,
            "scope": scope.rawValue,
            "quoteResults": "\(results.quotes.count)",
            "bookResults": "\(results.books.count)",
            "duration_ms": String(format: "%.2f", duration * 1000)
        ])

        return results
    }

    /// Assert search returns expected number of results
    func assertSearchCount(
        _ query: String,
        scope: SearchScope = .all,
        expectedQuotes: Int? = nil,
        expectedBooks: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let results = try await search(query, scope: scope)

        if let expected = expectedQuotes {
            XCTAssertEqual(
                results.quotes.count, expected,
                "Quote count mismatch for query '\(query)'",
                file: file, line: line
            )
        }

        if let expected = expectedBooks {
            XCTAssertEqual(
                results.books.count, expected,
                "Book count mismatch for query '\(query)'",
                file: file, line: line
            )
        }
    }

    /// Assert search returns no results
    func assertSearchEmpty(
        _ query: String,
        scope: SearchScope = .all,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        try await assertSearchCount(
            query,
            scope: scope,
            expectedQuotes: 0,
            expectedBooks: 0,
            file: file,
            line: line
        )
    }

    /// Assert search returns at least one result
    func assertSearchHasResults(
        _ query: String,
        scope: SearchScope = .all,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let results = try await search(query, scope: scope)
        XCTAssertFalse(
            results.isEmpty,
            "Expected results for query '\(query)' but got none",
            file: file, line: line
        )
    }

    // MARK: - Performance Helpers

    /// Measure search performance over multiple iterations
    func measureSearchPerformance(
        query: String,
        iterations: Int = 100
    ) async throws -> SearchPerformanceResult {
        var durations: [Double] = []

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await searchDatabase.search(query: query, scope: .all)
            durations.append(CFAbsoluteTimeGetCurrent() - start)
        }

        let result = SearchPerformanceResult(
            query: query,
            iterations: iterations,
            durations: durations
        )

        logger.info("Search performance measured", context: [
            "query": query,
            "iterations": "\(iterations)",
            "avg_ms": String(format: "%.2f", result.averageMs),
            "p95_ms": String(format: "%.2f", result.p95Ms),
            "max_ms": String(format: "%.2f", result.maxMs)
        ])

        return result
    }

    // MARK: - Index Statistics

    /// Get count of indexed quotes
    func indexedQuotesCount() async throws -> Int {
        try await searchDatabase.quotesCount()
    }

    /// Get count of indexed books
    func indexedBooksCount() async throws -> Int {
        try await searchDatabase.booksCount()
    }

    /// Assert indexed counts
    func assertIndexCounts(
        quotes: Int,
        books: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let actualQuotes = try await indexedQuotesCount()
        let actualBooks = try await indexedBooksCount()

        XCTAssertEqual(actualQuotes, quotes, "Indexed quote count mismatch", file: file, line: line)
        XCTAssertEqual(actualBooks, books, "Indexed book count mismatch", file: file, line: line)
    }
}

// MARK: - SearchPerformanceResult

/// Result of search performance measurement
struct SearchPerformanceResult {
    let query: String
    let iterations: Int
    let durations: [Double]

    var averageMs: Double {
        guard !durations.isEmpty else { return 0 }
        return (durations.reduce(0, +) / Double(durations.count)) * 1000
    }

    var minMs: Double {
        (durations.min() ?? 0) * 1000
    }

    var maxMs: Double {
        (durations.max() ?? 0) * 1000
    }

    var p95Ms: Double {
        guard !durations.isEmpty else { return 0 }
        let sorted = durations.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)] * 1000
    }

    var p99Ms: Double {
        guard !durations.isEmpty else { return 0 }
        let sorted = durations.sorted()
        let index = Int(Double(sorted.count) * 0.99)
        return sorted[min(index, sorted.count - 1)] * 1000
    }

    /// Assert average is under threshold
    func assertAverageUnder(
        _ maxMs: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThan(
            averageMs, maxMs,
            "Average search time \(String(format: "%.2f", averageMs))ms exceeds threshold \(maxMs)ms",
            file: file, line: line
        )
    }

    /// Assert P95 is under threshold
    func assertP95Under(
        _ maxMs: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThan(
            p95Ms, maxMs,
            "P95 search time \(String(format: "%.2f", p95Ms))ms exceeds threshold \(maxMs)ms",
            file: file, line: line
        )
    }

    /// Assert P99 is under threshold
    func assertP99Under(
        _ maxMs: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThan(
            p99Ms, maxMs,
            "P99 search time \(String(format: "%.2f", p99Ms))ms exceeds threshold \(maxMs)ms",
            file: file, line: line
        )
    }
}
