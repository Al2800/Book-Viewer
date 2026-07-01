import XCTest

@testable import BookQuotes

final class BookDeletionPromptTests: XCTestCase {
    func testBuildsTitleAndActionForBook() {
        let prompt = BookDeletionPrompt(
            bookTitle: "The Pleasure of Finding Things Out",
            quoteCount: 12
        )

        XCTAssertEqual(prompt.title, "Delete \"The Pleasure of Finding Things Out\"?")
        XCTAssertEqual(prompt.destructiveButtonTitle, "Delete Book and All Quotes")
    }

    func testMessageUsesSingularQuoteCount() {
        let prompt = BookDeletionPrompt(bookTitle: "The Alienist", quoteCount: 1)

        XCTAssertEqual(
            prompt.message,
            "This will permanently delete the book and all 1 quote. This cannot be undone."
        )
    }

    func testMessageUsesPluralQuoteCountForZeroAndMany() {
        let zeroPrompt = BookDeletionPrompt(bookTitle: "Empty Book", quoteCount: 0)
        let manyPrompt = BookDeletionPrompt(bookTitle: "Marked Book", quoteCount: 3)

        XCTAssertEqual(
            zeroPrompt.message,
            "This will permanently delete the book and all 0 quotes. This cannot be undone."
        )
        XCTAssertEqual(
            manyPrompt.message,
            "This will permanently delete the book and all 3 quotes. This cannot be undone."
        )
    }
}
