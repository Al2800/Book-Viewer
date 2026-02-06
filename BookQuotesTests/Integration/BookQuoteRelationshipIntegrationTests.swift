import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - BookQuoteRelationshipIntegrationTests

/// SwiftData integration tests that validate real relationship behaviors:
/// - Quote insertion attaches to Book
/// - Deleting Quote updates Book.quotes
/// - Deleting Book cascades to Quotes
/// - Production fetch descriptors behave as expected
@MainActor
final class BookQuoteRelationshipIntegrationTests: SwiftDataTestCase {

    func testInsertQuote_AttachesToBookAndInverseRelationship() throws {
        logger.step(1, "Insert a Book")
        let book = TestFixtures.book()
        modelContext.insert(book)
        try modelContext.save()

        logger.step(2, "Insert a Quote with its book set")
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "A deterministic quote long enough to pass validation."
        }
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(3, "Fetch and verify inverse relationship is present")
        let quoteID = quote.id
        let bookID = book.id
        let fetchedQuote = try modelContext.fetch(
            FetchDescriptor<Quote>(predicate: #Predicate { $0.id == quoteID })
        ).first
        XCTAssertEqual(fetchedQuote?.book?.id, bookID)

        let fetchedBook = try modelContext.fetch(
            FetchDescriptor<Book>(predicate: #Predicate { $0.id == bookID })
        ).first
        XCTAssertEqual(fetchedBook?.quotes.count, 1)
        XCTAssertEqual(fetchedBook?.quotes.first?.id, quote.id)
    }

    func testDeleteQuote_RemovesFromBookRelationship() throws {
        logger.step(1, "Insert Book + Quote")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "A deterministic quote that will be deleted later."
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Delete quote and save")
        modelContext.delete(quote)
        try modelContext.save()

        logger.step(3, "Verify book has zero quotes")
        let bookID = book.id
        let fetchedBook = try modelContext.fetch(
            FetchDescriptor<Book>(predicate: #Predicate { $0.id == bookID })
        ).first
        XCTAssertNotNil(fetchedBook)
        XCTAssertTrue(fetchedBook?.quotes.isEmpty ?? false)
    }

    func testDeleteBook_CascadesToQuotes() throws {
        logger.step(1, "Insert Book + multiple Quotes")
        let book = TestFixtures.book()

        let quote1 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Quote one is long enough to be valid and deterministic."
        }
        let quote2 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Quote two is also long enough to be valid and deterministic."
        }

        modelContext.insert(book)
        modelContext.insert(quote1)
        modelContext.insert(quote2)
        try modelContext.save()

        try assertBookCount(1)
        try assertQuoteCount(2)

        logger.step(2, "Delete book and save")
        modelContext.delete(book)
        try modelContext.save()

        logger.step(3, "Verify cascade delete removed quotes")
        try assertBookCount(0)
        try assertQuoteCount(0)
    }

    func testFetchDescriptor_BookWithQuotes_FiltersAndSortsByDateModifiedDescending() throws {
        logger.step(1, "Create two books that both have quotes")
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_100_000)

        let bookOld = TestFixtures.book { builder in
            builder.title = "Older Modified"
        }
        bookOld.dateModified = older

        let bookNew = TestFixtures.book { builder in
            builder.title = "Newer Modified"
        }
        bookNew.dateModified = newer

        let quoteOld = TestFixtures.quote { builder in
            builder.book = bookOld
            builder.text = "Quote for older-modified book, long enough to be valid."
        }
        let quoteNew = TestFixtures.quote { builder in
            builder.book = bookNew
            builder.text = "Quote for newer-modified book, long enough to be valid."
        }

        modelContext.insert(bookOld)
        modelContext.insert(bookNew)
        modelContext.insert(quoteOld)
        modelContext.insert(quoteNew)
        try modelContext.save()

        logger.step(2, "Fetch using production descriptor")
        let results = try modelContext.fetch(Book.withQuotes)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.id, bookNew.id)
        XCTAssertEqual(results.last?.id, bookOld.id)
    }

    func testFetchDescriptor_QuoteRecent_SortsByCaptureDateDescending() throws {
        logger.step(1, "Insert two quotes with deterministic capture dates")
        let book = TestFixtures.book()
        modelContext.insert(book)

        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_100_000)

        let q1 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Older quote content that is long enough to be valid."
        }
        q1.captureDate = older

        let q2 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Newer quote content that is long enough to be valid."
        }
        q2.captureDate = newer

        modelContext.insert(q1)
        modelContext.insert(q2)
        try modelContext.save()

        logger.step(2, "Fetch using production descriptor")
        let results = try modelContext.fetch(Quote.recent)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.first?.id, q2.id)
        XCTAssertEqual(results.last?.id, q1.id)
    }
}
