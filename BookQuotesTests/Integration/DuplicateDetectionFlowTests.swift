import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - DuplicateDetectionFlowTests

@MainActor
final class DuplicateDetectionFlowTests: SwiftDataTestCase {

    func testDuplicateDetectionFindsExactMatch() throws {
        logger.step(1, "Creating quotes")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Consistent systems beat goals"
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Checking duplicates")
        let detector = DuplicateDetector(modelContext: modelContext)
        let result = detector.findExactDuplicate(text: "Consistent systems beat goals", inBook: book)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, quote.id)
        logger.success("Exact duplicate detected")
    }

    func testDuplicateDetectionFindsSimilarMatch() throws {
        logger.step(1, "Creating quotes")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Focus on systems, not goals"
        }
        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Checking similar duplicates")
        let detector = DuplicateDetector(modelContext: modelContext, configuration: .loose)
        let results = detector.checkForDuplicates(text: "Focus on systems not goals", inBook: book)

        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.first?.similarityScore ?? 0 > 0.8)
        logger.success("Similar duplicate detected")
    }

    func testDuplicateDetectionRespectsBookScope() throws {
        logger.step(1, "Creating quotes across books")
        let book1 = TestFixtures.book { builder in
            builder.title = "Book A"
        }
        let book2 = TestFixtures.book { builder in
            builder.title = "Book B"
        }
        let quote = TestFixtures.quote { builder in
            builder.book = book1
            builder.text = "Scoped quote"
        }
        modelContext.insert(book1)
        modelContext.insert(book2)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Checking duplicates in other book")
        let detector = DuplicateDetector(modelContext: modelContext)
        let results = detector.checkForDuplicates(text: "Scoped quote", inBook: book2)

        XCTAssertTrue(results.isEmpty)
        logger.success("Book scope respected")
    }
}
