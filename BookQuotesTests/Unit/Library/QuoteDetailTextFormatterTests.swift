import XCTest

@testable import BookQuotes

final class QuoteDetailTextFormatterTests: XCTestCase {

    func testShareTextIncludesQuoteBookAuthorAndPage() {
        let book = Book(title: "The Pleasure of Finding Things Out", author: "Richard Feynman")
        let quote = Quote(text: "I learned very early the difference between knowing the name of something and knowing something.", book: book)
        quote.pageNumber = 42

        let text = QuoteDetailTextFormatter.shareText(for: quote)

        XCTAssertEqual(
            text,
            "\"I learned very early the difference between knowing the name of something and knowing something.\"\n\n— The Pleasure of Finding Things Out by Richard Feynman, p. 42"
        )
    }

    func testShareTextOmitsAttributionWhenBookIsMissing() {
        let quote = Quote(text: "What I cannot create, I do not understand.")
        quote.pageNumber = 12

        XCTAssertEqual(
            QuoteDetailTextFormatter.shareText(for: quote),
            "\"What I cannot create, I do not understand.\""
        )
    }

    func testShareTextOmitsPageWhenPageIsMissing() {
        let book = Book(title: "Atomic Habits", author: "James Clear")
        let quote = Quote(text: "You do not rise to the level of your goals.", book: book)

        XCTAssertEqual(
            QuoteDetailTextFormatter.shareText(for: quote),
            "\"You do not rise to the level of your goals.\"\n\n— Atomic Habits by James Clear"
        )
    }
}
