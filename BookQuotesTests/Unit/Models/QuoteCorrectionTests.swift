import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - QuoteCorrectionTests

@MainActor
final class QuoteCorrectionTests: SwiftDataTestCase {

    func testRecordTextCorrectionCreatesEntry() throws {
        logger.step(1, "Creating quote")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.text = "Original"
        }

        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Recording correction")
        quote.recordTextCorrection(original: "Original", corrected: "Updated", context: modelContext)
        try modelContext.save()

        logger.step(3, "Fetching corrections")
        let count = try modelContext.fetchCount(FetchDescriptor<QuoteCorrection>())
        XCTAssertEqual(count, 1)
        XCTAssertNotNil(quote.dateModified)

        logger.success("Text correction recorded")
    }

    func testRecordPageCorrectionStoresValues() throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
        }

        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        quote.recordPageCorrection(originalPage: 10, correctedPage: 12, context: modelContext)
        try modelContext.save()

        let corrections = try modelContext.fetch(FetchDescriptor<QuoteCorrection>())
        let correction = try XCTUnwrap(corrections.first)
        XCTAssertEqual(correction.originalPageNumber, 10)
        XCTAssertEqual(correction.correctedPageNumber, 12)
        XCTAssertEqual(correction.correctionType, .pageNumber)
    }
}
