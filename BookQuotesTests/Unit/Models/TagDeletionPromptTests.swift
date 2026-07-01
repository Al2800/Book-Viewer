import XCTest

@testable import BookQuotes

final class TagDeletionPromptTests: XCTestCase {
    func testPromptUsesStableTitleAndActionTitle() {
        let prompt = TagDeletionPrompt(quoteCount: 3)

        XCTAssertEqual(prompt.title, "Delete Tag?")
        XCTAssertEqual(prompt.destructiveActionTitle, "Delete Tag")
    }

    func testMessageUsesSingularQuoteCount() {
        let prompt = TagDeletionPrompt(quoteCount: 1)

        XCTAssertEqual(
            prompt.message,
            "This will remove the tag from all 1 quote. This cannot be undone."
        )
    }

    func testMessageUsesPluralQuoteCount() {
        let prompt = TagDeletionPrompt(quoteCount: 2)

        XCTAssertEqual(
            prompt.message,
            "This will remove the tag from all 2 quotes. This cannot be undone."
        )
    }
}
