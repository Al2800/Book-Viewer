import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - TagModelTests

@MainActor
final class TagModelTests: SwiftDataTestCase {

    func testTagNormalizesName() throws {
        logger.step(1, "Creating tag with mixed case and whitespace")
        let tag = Tag(name: "  Productivity ")

        logger.step(2, "Verifying normalization")
        XCTAssertEqual(tag.name, "productivity")
        XCTAssertEqual(tag.colorName, "blue")
        XCTAssertEqual(tag.quoteCount, 0)
        XCTAssertNotNil(tag.dateCreated)

        logger.success("Tag name normalization works")
    }

    func testTagPersistsQuotes() throws {
        logger.step(1, "Creating tag and quote")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
        }
        let tag = TestFixtures.tag { builder in
            builder.quotes = [quote]
        }

        modelContext.insert(book)
        modelContext.insert(quote)
        try insertTag(tag)

        logger.step(2, "Fetching tag and verifying quote count")
        let fetched = try XCTUnwrap(fetchAllTags().first)
        XCTAssertEqual(fetched.quoteCount, 1)

        logger.success("Tag quote relationship persists")
    }
}
