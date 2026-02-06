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

// MARK: - BookModelFetchDescriptorsIntegrationTests

/// SwiftData integration tests that validate production fetch descriptors and predicates
/// on real in-memory SwiftData containers (no CloudKit).
@MainActor
final class BookModelFetchDescriptorsIntegrationTests: SwiftDataTestCase {

    func testFetchDescriptor_BookRecentlyAdded_SortsByDateAddedDescending() throws {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_100_000)

        let bookOld = TestFixtures.book { builder in
            builder.title = "Old Added"
            builder.author = "A"
        }
        bookOld.dateAdded = older

        let bookNew = TestFixtures.book { builder in
            builder.title = "New Added"
            builder.author = "B"
        }
        bookNew.dateAdded = newer

        modelContext.insert(bookOld)
        modelContext.insert(bookNew)
        try modelContext.save()

        let results = try modelContext.fetch(Book.recentlyAdded)
        XCTAssertEqual(results.map(\.id), [bookNew.id, bookOld.id])
    }

    func testFetchDescriptor_BookCurrentlyReading_FiltersAndSortsByDateStartedDescending() throws {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_100_000)

        let readingOld = TestFixtures.book { builder in
            builder.title = "Reading Old"
            builder.author = "Author"
        }
        readingOld.status = .currentlyReading
        readingOld.dateStarted = older

        let readingNew = TestFixtures.book { builder in
            builder.title = "Reading New"
            builder.author = "Author"
        }
        readingNew.status = .currentlyReading
        readingNew.dateStarted = newer

        let want = TestFixtures.book { builder in
            builder.title = "Want To Read"
            builder.author = "Author"
        }
        want.status = .wantToRead

        modelContext.insert(readingOld)
        modelContext.insert(readingNew)
        modelContext.insert(want)
        try modelContext.save()

        let results = try modelContext.fetch(Book.currentlyReading)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.map(\.id), [readingNew.id, readingOld.id])
    }

    func testFetchDescriptor_BookSearch_MatchesTitleOrAuthor() throws {
        let book1 = TestFixtures.book { builder in
            builder.title = "Atomic Habits"
            builder.author = "James Clear"
        }
        let book2 = TestFixtures.book { builder in
            builder.title = "Thinking, Fast and Slow"
            builder.author = "Daniel Kahneman"
        }
        modelContext.insert(book1)
        modelContext.insert(book2)
        try modelContext.save()

        let byAuthor = try modelContext.fetch(Book.search("clear"))
        XCTAssertEqual(byAuthor.count, 1)
        XCTAssertEqual(byAuthor.first?.id, book1.id)

        let byTitle = try modelContext.fetch(Book.search("thinking"))
        XCTAssertEqual(byTitle.count, 1)
        XCTAssertEqual(byTitle.first?.id, book2.id)
    }

    func testFetchDescriptor_QuoteFavorites_FiltersAndSortsByCaptureDateDescending() throws {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_700_100_000)

        let book = TestFixtures.book()
        modelContext.insert(book)

        let favOld = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Favorite older quote content that is long enough to be valid."
        }
        favOld.isFavorite = true
        favOld.captureDate = older

        let favNew = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Favorite newer quote content that is long enough to be valid."
        }
        favNew.isFavorite = true
        favNew.captureDate = newer

        let notFav = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Non-favorite quote content that is long enough to be valid."
        }
        notFav.isFavorite = false

        modelContext.insert(favOld)
        modelContext.insert(favNew)
        modelContext.insert(notFav)
        try modelContext.save()

        let results = try modelContext.fetch(Quote.favorites)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.map(\.id), [favNew.id, favOld.id])
    }

    func testFetchDescriptor_QuoteSearch_MatchesTextOrMarginNote() throws {
        let book = TestFixtures.book()
        modelContext.insert(book)

        let q1 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "This quote mentions productivity and habit building."
        }
        q1.marginNote = "underline this"

        let q2 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "This quote is about something else entirely."
        }
        q2.marginNote = "remember: productivity"

        let q3 = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Unrelated quote with no matching terms."
        }

        modelContext.insert(q1)
        modelContext.insert(q2)
        modelContext.insert(q3)
        try modelContext.save()

        let results = try modelContext.fetch(Quote.search("productivity"))
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.map(\.id).contains(q1.id))
        XCTAssertTrue(results.map(\.id).contains(q2.id))
    }
}
