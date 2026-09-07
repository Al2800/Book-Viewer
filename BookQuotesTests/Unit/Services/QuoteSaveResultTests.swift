import XCTest
import SwiftData

@testable import BookQuotes

final class QuoteSaveResultTests: XCTestCase {
    func testFullSuccessSummaryAndRate() {
        let book = Book(title: "The Book", author: "The Author")
        let savedQuotes = [
            Quote(text: "A sufficiently long saved quote.", book: book),
            Quote(text: "Another sufficiently long saved quote.", book: book)
        ]

        let result = BatchSaveResult(
            savedQuotes: savedQuotes,
            failures: [],
            book: book
        )

        XCTAssertTrue(result.isFullSuccess)
        XCTAssertFalse(result.isPartialSuccess)
        XCTAssertFalse(result.isFullFailure)
        XCTAssertEqual(result.totalAttempted, 2)
        XCTAssertEqual(result.successRate, 1)
        XCTAssertEqual(result.summary, "Saved 2 quotes")
    }

    func testPartialSuccessSummaryAndRate() {
        let book = Book(title: "The Book", author: "The Author")
        let savedQuotes = [
            Quote(text: "A sufficiently long saved quote.", book: book)
        ]
        let failures = [
            SaveFailure(
                index: 1,
                extractedQuote: ExtractedQuote(text: "Too short"),
                error: ValidationError.quoteTooShort
            )
        ]

        let result = BatchSaveResult(
            savedQuotes: savedQuotes,
            failures: failures,
            book: book
        )

        XCTAssertFalse(result.isFullSuccess)
        XCTAssertTrue(result.isPartialSuccess)
        XCTAssertFalse(result.isFullFailure)
        XCTAssertEqual(result.totalAttempted, 2)
        XCTAssertEqual(result.successRate, 0.5)
        XCTAssertEqual(result.summary, "Saved 1 of 2 quotes")
    }

    func testFullFailureSummaryUsesSingularQuoteWhenOneFails() {
        let book = Book(title: "The Book", author: "The Author")
        let failures = [
            SaveFailure(
                index: 0,
                extractedQuote: ExtractedQuote(text: "Too short"),
                error: ValidationError.quoteTooShort
            )
        ]

        let result = BatchSaveResult(
            savedQuotes: [],
            failures: failures,
            book: book
        )

        XCTAssertFalse(result.isFullSuccess)
        XCTAssertFalse(result.isPartialSuccess)
        XCTAssertTrue(result.isFullFailure)
        XCTAssertEqual(result.totalAttempted, 1)
        XCTAssertEqual(result.successRate, 0)
        XCTAssertEqual(result.summary, "Failed to save 1 quote")
    }

    func testSaveFailureUsesValidationErrorDescription() {
        let failure = SaveFailure(
            index: 0,
            extractedQuote: ExtractedQuote(text: "Short"),
            error: ValidationError.quoteTooShort
        )

        XCTAssertEqual(failure.errorMessage, "Quote must be at least 10 characters")
    }

    func testQuoteSaveErrorDescriptions() {
        XCTAssertEqual(
            QuoteSaveError.invalidQuoteData("missing text").errorDescription,
            "Invalid quote data: missing text"
        )
        XCTAssertEqual(
            QuoteSaveError.duplicateQuote.errorDescription,
            "This quote already exists in your library"
        )
    }
}

final class QuoteSaveRecoveryTests: SwiftDataTestCase {
    private struct InjectedPersistenceFailure: Error {}

    func testFailedInsertCannotBeCommittedByALaterSaveAndPreservesOtherEdits() throws {
        modelContext.autosaveEnabled = false
        let book = Book(title: "Original title", author: "Author")
        let previousDate = Date(timeIntervalSince1970: 100)
        book.dateLastQuoteAdded = previousDate
        modelContext.insert(book)
        try modelContext.save()
        book.title = "Unrelated unsaved edit"
        let service = QuoteSaveService(modelContext: modelContext, persistQuoteChanges: {
            throw InjectedPersistenceFailure()
        })
        XCTAssertThrowsError(try service.save(ExtractedQuote(text: "This candidate must remain unsaved."), to: book))
        XCTAssertEqual(book.title, "Unrelated unsaved edit")
        XCTAssertEqual(book.dateLastQuoteAdded, previousDate)
        XCTAssertTrue(book.quotes.isEmpty)

        try modelContext.save()
        let freshContext = ModelContext(modelContainer)
        XCTAssertTrue(try freshContext.fetch(FetchDescriptor<Quote>()).isEmpty,
                      "A later save must not resurrect the failed candidate")
    }

    func testInjectedPartialFailureRetainsOnlyTheFailedSubmittedCandidateForRetry() throws {
        modelContext.autosaveEnabled = false
        let book = Book(title: "A book", author: "Author")
        modelContext.insert(book)
        try modelContext.save()
        let excluded = EditableQuote(pageId: UUID(), text: "Excluded by the reader.", markingType: "underline")
        let failed = EditableQuote(pageId: UUID(), text: "This passage fails to persist.", markingType: "underline")
        let saved = EditableQuote(pageId: UUID(), text: "This passage is successfully saved.", markingType: "underline")
        var state = ExtractionReviewQuoteState(editingQuotes: [excluded, saved, failed])
        state.setSelected(false, id: excluded.id)
        var attempts = 0
        let service = QuoteSaveService(modelContext: modelContext, persistQuoteChanges: {
            attempts += 1
            if attempts == 1 { throw InjectedPersistenceFailure() }
            try self.modelContext.save()
        })
        let submitted = [failed, saved]
        let result = service.saveMultiple(submitted.map { $0.toExtractedQuote() }, to: book)
        XCTAssertEqual(attempts, 2)
        XCTAssertTrue(result.isPartialSuccess)
        XCTAssertEqual(result.failures.map(\.index), [0])
        XCTAssertEqual(result.savedQuotes.map(\.text), [saved.text])
        state.applySaveResult(submittedIDs: submitted.map(\.id), failures: result.failures)
        XCTAssertEqual(state.selectedQuotes.map(\.id), [failed.id])
        XCTAssertEqual(state.editingQuotes.map(\.id), [excluded.id, failed.id])

        let retry = QuoteSaveService(modelContext: modelContext).saveMultiple(
            state.selectedQuotes.map { $0.toExtractedQuote() }, to: book
        )
        XCTAssertTrue(retry.isFullSuccess)
        let stored = try ModelContext(modelContainer).fetch(FetchDescriptor<Quote>())
        XCTAssertEqual(Set(stored.map(\.text)), Set([saved.text, failed.text]))
        XCTAssertEqual(stored.count, 2, "Retry must not duplicate the already-saved passage")
    }

    func testValidationFailureDoesNotAttachAnInvalidQuoteToTheBook() throws {
        let book = Book(title: "A book", author: "Author")
        modelContext.insert(book)
        try modelContext.save()
        XCTAssertThrowsError(try QuoteSaveService(modelContext: modelContext).save(ExtractedQuote(text: "Short"), to: book))
        XCTAssertTrue(book.quotes.isEmpty)
        try modelContext.save()
        XCTAssertTrue(try ModelContext(modelContainer).fetch(FetchDescriptor<Quote>()).isEmpty)
    }
}
