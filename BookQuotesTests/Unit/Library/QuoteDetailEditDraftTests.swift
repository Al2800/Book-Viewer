import XCTest
import SwiftData

@testable import BookQuotes

final class QuoteDetailEditDraftTests: SwiftDataTestCase {

    func testAppliesEditedTextMarginNotePageNumberAndModifiedDate() throws {
        let quote = Quote(text: "Original quote")
        modelContext.insert(quote)
        try modelContext.save()

        let modifiedDate = Date(timeIntervalSince1970: 1_234)

        QuoteDetailEditDraft(
            text: "Edited quote",
            marginNote: "Updated note",
            pageNumberText: "42",
            modifiedDate: modifiedDate
        )
        .apply(to: quote, in: modelContext)

        XCTAssertEqual(quote.text, "Edited quote")
        XCTAssertEqual(quote.marginNote, "Updated note")
        XCTAssertEqual(quote.pageNumber, 42)
        XCTAssertEqual(quote.dateModified, modifiedDate)

        let corrections = try modelContext.fetch(QuoteCorrection.all)
        XCTAssertEqual(corrections.count, 2)
        XCTAssertTrue(corrections.contains { $0.correctionType == .textEdit })
        XCTAssertTrue(corrections.contains { $0.correctionType == .marginNote })
    }

    func testEmptyMarginNoteAndInvalidPageNumberClearExistingValues() throws {
        let quote = Quote(text: "Original quote")
        quote.marginNote = "Existing note"
        quote.pageNumber = 25
        modelContext.insert(quote)
        try modelContext.save()

        QuoteDetailEditDraft(
            text: "Edited quote",
            marginNote: "",
            pageNumberText: "not a page",
            modifiedDate: Date(timeIntervalSince1970: 1_235)
        )
        .apply(to: quote, in: modelContext)

        XCTAssertNil(quote.marginNote)
        XCTAssertNil(quote.pageNumber)

        let corrections = try modelContext.fetch(QuoteCorrection.all)
        XCTAssertEqual(corrections.count, 3)
        XCTAssertTrue(corrections.contains { $0.correctionType == .textEdit })
        XCTAssertTrue(corrections.contains { $0.correctionType == .marginNote })
        XCTAssertTrue(corrections.contains { $0.correctionType == .pageNumber })
    }

    func testUnchangedFieldsDoNotRecordCorrections() throws {
        let quote = Quote(text: "Same quote")
        quote.marginNote = "Same note"
        quote.pageNumber = 10
        modelContext.insert(quote)
        try modelContext.save()

        QuoteDetailEditDraft(
            text: "Same quote",
            marginNote: "Same note",
            pageNumberText: "10"
        )
        .apply(to: quote, in: modelContext)

        let corrections = try modelContext.fetch(QuoteCorrection.all)
        XCTAssertTrue(corrections.isEmpty)
    }
}
