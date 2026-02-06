import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - CollectionTagRelationshipIntegrationTests

/// SwiftData integration tests for tag and collection relationships across Book and Quote.
@MainActor
final class CollectionTagRelationshipIntegrationTests: SwiftDataTestCase {

    func testTaggingBook_PersistsBidirectionalRelationship() throws {
        logger.step(1, "Insert Book + Tag and attach relationship")
        let book = TestFixtures.book()
        let tag = TestFixtures.tag { builder in
            builder.name = "Productivity"
        }
        book.tags.append(tag)

        modelContext.insert(book)
        modelContext.insert(tag)
        try modelContext.save()

        logger.step(2, "Fetch and verify both sides")
        let bookID = book.id
        let tagID = tag.id

        let fetchedBook = try modelContext.fetch(
            FetchDescriptor<Book>(predicate: #Predicate { $0.id == bookID })
        ).first
        XCTAssertEqual(fetchedBook?.tags.count, 1)
        XCTAssertEqual(fetchedBook?.tags.first?.id, tagID)

        let fetchedTag = try modelContext.fetch(
            FetchDescriptor<Tag>(predicate: #Predicate { $0.id == tagID })
        ).first
        XCTAssertEqual(fetchedTag?.books.count, 1)
        XCTAssertEqual(fetchedTag?.books.first?.id, bookID)
    }

    func testTaggingQuote_PersistsBidirectionalRelationship() throws {
        logger.step(1, "Insert Book + Quote + Tag and attach relationship")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "A quote tagged for integration testing and long enough to be valid."
        }
        let tag = TestFixtures.tag { builder in
            builder.name = "highlights"
        }
        quote.tags.append(tag)

        modelContext.insert(book)
        modelContext.insert(quote)
        modelContext.insert(tag)
        try modelContext.save()

        logger.step(2, "Fetch and verify both sides")
        let quoteID = quote.id
        let tagID = tag.id

        let fetchedQuote = try modelContext.fetch(
            FetchDescriptor<Quote>(predicate: #Predicate { $0.id == quoteID })
        ).first
        XCTAssertEqual(fetchedQuote?.tags.count, 1)
        XCTAssertEqual(fetchedQuote?.tags.first?.id, tagID)

        let fetchedTag = try modelContext.fetch(
            FetchDescriptor<Tag>(predicate: #Predicate { $0.id == tagID })
        ).first
        XCTAssertEqual(fetchedTag?.quotes.count, 1)
        XCTAssertEqual(fetchedTag?.quotes.first?.id, quoteID)
    }

    func testCollectionMembership_PersistsForBooksAndQuotes() throws {
        logger.step(1, "Insert Book + Quote + Collection and attach memberships")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "A quote in a collection for integration testing and long enough to be valid."
        }
        let collection = TestFixtures.collection { builder in
            builder.name = "Favorites"
            builder.icon = "star"
            builder.colorName = "yellow"
            builder.books = [book]
            builder.quotes = [quote]
        }

        modelContext.insert(book)
        modelContext.insert(quote)
        modelContext.insert(collection)
        try modelContext.save()

        logger.step(2, "Fetch and verify both sides for book and quote")
        let bookID = book.id
        let quoteID = quote.id
        let collectionID = collection.id

        let fetchedCollection = try modelContext.fetch(
            FetchDescriptor<Collection>(predicate: #Predicate { $0.id == collectionID })
        ).first
        XCTAssertEqual(fetchedCollection?.books.count, 1)
        XCTAssertEqual(fetchedCollection?.quotes.count, 1)

        let fetchedBook = try modelContext.fetch(
            FetchDescriptor<Book>(predicate: #Predicate { $0.id == bookID })
        ).first
        XCTAssertEqual(fetchedBook?.collections.count, 1)
        XCTAssertEqual(fetchedBook?.collections.first?.id, collectionID)

        let fetchedQuote = try modelContext.fetch(
            FetchDescriptor<Quote>(predicate: #Predicate { $0.id == quoteID })
        ).first
        XCTAssertEqual(fetchedQuote?.collections.count, 1)
        XCTAssertEqual(fetchedQuote?.collections.first?.id, collectionID)
    }

    func testDeleteTag_DoesNotDeleteBooksOrQuotes() throws {
        logger.step(1, "Insert Book + Quote + Tag")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "A quote that survives tag deletion and is long enough to be valid."
        }
        let tag = TestFixtures.tag { builder in
            builder.name = "temporary"
        }
        book.tags.append(tag)
        quote.tags.append(tag)

        modelContext.insert(book)
        modelContext.insert(quote)
        modelContext.insert(tag)
        try modelContext.save()

        try assertBookCount(1)
        try assertQuoteCount(1)
        try assertTagCount(1)

        logger.step(2, "Delete tag and verify book/quote remain")
        modelContext.delete(tag)
        try modelContext.save()

        try assertBookCount(1)
        try assertQuoteCount(1)
        try assertTagCount(0)
    }

    func testDeleteCollection_DoesNotDeleteBooksOrQuotes() throws {
        logger.step(1, "Insert Book + Quote + Collection")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "A quote that survives collection deletion and is long enough to be valid."
        }
        let collection = TestFixtures.collection { builder in
            builder.name = "To Remove"
            builder.books = [book]
            builder.quotes = [quote]
        }

        modelContext.insert(book)
        modelContext.insert(quote)
        modelContext.insert(collection)
        try modelContext.save()

        try assertBookCount(1)
        try assertQuoteCount(1)
        try assertCollectionCount(1)

        logger.step(2, "Delete collection and verify book/quote remain")
        modelContext.delete(collection)
        try modelContext.save()

        try assertBookCount(1)
        try assertQuoteCount(1)
        try assertCollectionCount(0)
    }
}

