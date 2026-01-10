import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - SwiftDataTestCase

/// Base test case providing in-memory SwiftData infrastructure.
/// Use @MainActor since SwiftData contexts are main-actor bound.
///
/// Example usage:
/// ```swift
/// final class BookModelTests: SwiftDataTestCase {
///     func testBookCreation() async throws {
///         logger.step(1, "Creating a book")
///         let book = TestFixtures.atomicHabits
///
///         logger.step(2, "Inserting book into context")
///         try insertBook(book)
///
///         logger.step(3, "Verifying book was saved")
///         try assertBookCount(1)
///     }
/// }
/// ```
@MainActor
class SwiftDataTestCase: XCTestCase {

    // MARK: - Properties

    /// In-memory model container - fresh for each test
    var modelContainer: ModelContainer!

    /// Main context for test operations
    var modelContext: ModelContext!

    /// Test logger for detailed output
    var logger: TestLogger!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        logger = TestLogger(testName: name)
        logger.info("Setting up SwiftData test environment")

        // Create in-memory container with all models
        let schema = Schema([
            Book.self,
            Quote.self,
            MarkingDefinition.self,
            Collection.self,
            Tag.self,
            CaptureSession.self,
            PageCapture.self,
            CaptureQueueItem.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = modelContainer.mainContext
            logger.success("In-memory ModelContainer created")
        } catch {
            logger.error("Failed to create ModelContainer", error: error)
            throw error
        }

        // Seed default marking definitions
        MarkingDefinition.seedDefaults(in: modelContext)
        logger.debug("Seeded default marking definitions")
    }

    override func tearDown() async throws {
        logger.info("Tearing down SwiftData test environment")

        // Clear all data
        try? modelContext.delete(model: Quote.self)
        try? modelContext.delete(model: Book.self)
        try? modelContext.delete(model: MarkingDefinition.self)
        try? modelContext.delete(model: Collection.self)
        try? modelContext.delete(model: Tag.self)
        try? modelContext.delete(model: CaptureSession.self)
        try? modelContext.delete(model: PageCapture.self)
        try? modelContext.delete(model: CaptureQueueItem.self)

        modelContext = nil
        modelContainer = nil

        print(logger.summary())

        try await super.tearDown()
    }

    // MARK: - Book Helpers

    /// Insert and save a book with its quotes
    func insertBook(_ book: Book) throws {
        modelContext.insert(book)
        try modelContext.save()
        logger.debug("Inserted book", context: [
            "title": book.title,
            "quoteCount": "\(book.quotes.count)"
        ])
    }

    /// Insert multiple books
    func insertBooks(_ books: [Book]) throws {
        for book in books {
            modelContext.insert(book)
        }
        try modelContext.save()
        logger.debug("Inserted books", context: ["count": "\(books.count)"])
    }

    /// Fetch all books
    func fetchAllBooks() throws -> [Book] {
        let descriptor = FetchDescriptor<Book>(sortBy: [SortDescriptor(\.title)])
        return try modelContext.fetch(descriptor)
    }

    /// Assert book count
    func assertBookCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let actual = try modelContext.fetchCount(FetchDescriptor<Book>())
        XCTAssertEqual(actual, expected, "Book count mismatch", file: file, line: line)
    }

    // MARK: - Quote Helpers

    /// Insert a quote into the context
    func insertQuote(_ quote: Quote) throws {
        modelContext.insert(quote)
        try modelContext.save()
        logger.debug("Inserted quote", context: [
            "text": String(quote.text.prefix(50)),
            "bookTitle": quote.book?.title ?? "none"
        ])
    }

    /// Fetch all quotes
    func fetchAllQuotes() throws -> [Quote] {
        let descriptor = FetchDescriptor<Quote>(sortBy: [SortDescriptor(\.captureDate)])
        return try modelContext.fetch(descriptor)
    }

    /// Assert quote count
    func assertQuoteCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let actual = try modelContext.fetchCount(FetchDescriptor<Quote>())
        XCTAssertEqual(actual, expected, "Quote count mismatch", file: file, line: line)
    }

    // MARK: - Collection Helpers

    /// Insert a collection into the context
    func insertCollection(_ collection: Collection) throws {
        modelContext.insert(collection)
        try modelContext.save()
        logger.debug("Inserted collection", context: ["name": collection.name])
    }

    /// Fetch all collections
    func fetchAllCollections() throws -> [Collection] {
        let descriptor = FetchDescriptor<Collection>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }

    /// Assert collection count
    func assertCollectionCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let actual = try modelContext.fetchCount(FetchDescriptor<Collection>())
        XCTAssertEqual(actual, expected, "Collection count mismatch", file: file, line: line)
    }

    // MARK: - Tag Helpers

    /// Insert a tag into the context
    func insertTag(_ tag: Tag) throws {
        modelContext.insert(tag)
        try modelContext.save()
        logger.debug("Inserted tag", context: ["name": tag.name])
    }

    /// Fetch all tags
    func fetchAllTags() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor)
    }

    /// Assert tag count
    func assertTagCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let actual = try modelContext.fetchCount(FetchDescriptor<Tag>())
        XCTAssertEqual(actual, expected, "Tag count mismatch", file: file, line: line)
    }

    // MARK: - MarkingDefinition Helpers

    /// Fetch all marking definitions
    func fetchAllMarkingDefinitions() throws -> [MarkingDefinition] {
        let descriptor = FetchDescriptor<MarkingDefinition>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch only user-defined marking definitions
    func fetchCustomMarkingDefinitions() throws -> [MarkingDefinition] {
        let descriptor = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate { !$0.isSystemDefault },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Assert marking definition count
    func assertMarkingDefinitionCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let actual = try modelContext.fetchCount(FetchDescriptor<MarkingDefinition>())
        XCTAssertEqual(actual, expected, "MarkingDefinition count mismatch", file: file, line: line)
    }

    // MARK: - Performance Helpers

    /// Measure async operation with logging
    func measureAsync(
        _ name: String,
        operation: () async throws -> Void
    ) async rethrows {
        let start = CFAbsoluteTimeGetCurrent()
        try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        logger.info("Performance: \(name)", context: [
            "duration_ms": String(format: "%.2f", duration * 1000)
        ])
    }

    /// Measure sync operation with logging
    func measureSync(
        _ name: String,
        operation: () throws -> Void
    ) rethrows {
        let start = CFAbsoluteTimeGetCurrent()
        try operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        logger.info("Performance: \(name)", context: [
            "duration_ms": String(format: "%.2f", duration * 1000)
        ])
    }

    // MARK: - Context Helpers

    /// Save the model context
    func saveContext() throws {
        try modelContext.save()
        logger.debug("Context saved")
    }

    /// Clear all data from context
    func clearAllData() throws {
        try modelContext.delete(model: Quote.self)
        try modelContext.delete(model: Book.self)
        try modelContext.delete(model: Collection.self)
        try modelContext.delete(model: Tag.self)
        // Don't delete marking definitions - they should persist
        try modelContext.save()
        logger.debug("All data cleared")
    }

    // MARK: - Assertion Helpers

    /// Assert that the database is empty (except marking definitions)
    func assertDatabaseEmpty(
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try assertBookCount(0, file: file, line: line)
        try assertQuoteCount(0, file: file, line: line)
        try assertCollectionCount(0, file: file, line: line)
        try assertTagCount(0, file: file, line: line)
    }
}
