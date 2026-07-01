import XCTest

@testable import BookQuotes

final class QuoteDeletionPromptTests: XCTestCase {
    func testPromptUsesStableCopy() {
        let prompt = QuoteDeletionPrompt()

        XCTAssertEqual(prompt.title, "Delete Quote?")
        XCTAssertEqual(prompt.destructiveActionTitle, "Delete")
        XCTAssertEqual(prompt.message, "This action cannot be undone.")
    }
}
