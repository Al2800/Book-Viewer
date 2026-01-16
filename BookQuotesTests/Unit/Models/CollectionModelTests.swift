import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - CollectionModelTests

@MainActor
final class CollectionModelTests: SwiftDataTestCase {

    func testCollectionDefaults() throws {
        logger.step(1, "Creating collection with defaults")
        let collection = Collection(name: "Highlights")

        logger.step(2, "Validating defaults")
        XCTAssertNotNil(collection.id)
        XCTAssertEqual(collection.name, "Highlights")
        XCTAssertEqual(collection.icon, "folder")
        XCTAssertEqual(collection.colorName, "blue")
        XCTAssertEqual(collection.sortOrder, 0)
        XCTAssertTrue(collection.books.isEmpty)
        XCTAssertTrue(collection.quotes.isEmpty)
        XCTAssertEqual(collection.quoteCount, 0)
        XCTAssertNotNil(collection.dateCreated)
        XCTAssertNotNil(collection.dateModified)

        logger.success("Collection defaults are correct")
    }

    func testCollectionPersistsBooksAndQuotes() throws {
        logger.step(1, "Creating related book and quote")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
        }

        logger.step(2, "Creating collection with relationships")
        let collection = TestFixtures.collection { builder in
            builder.books = [book]
            builder.quotes = [quote]
        }

        modelContext.insert(book)
        modelContext.insert(quote)
        try insertCollection(collection)

        logger.step(3, "Fetching and validating relationships")
        let fetched = try XCTUnwrap(fetchAllCollections().first)
        XCTAssertEqual(fetched.books.count, 1)
        XCTAssertEqual(fetched.quotes.count, 1)
        XCTAssertEqual(fetched.quoteCount, 1)

        logger.success("Collection relationships persist")
    }
}
