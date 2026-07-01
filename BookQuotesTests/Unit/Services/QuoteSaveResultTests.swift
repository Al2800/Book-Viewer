import XCTest

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
