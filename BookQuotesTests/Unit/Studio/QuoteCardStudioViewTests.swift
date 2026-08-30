import XCTest
import SwiftUI
@testable import BookQuotes

@MainActor
final class QuoteCardStudioViewTests: XCTestCase {

    func testQuoteCanvasCardInitializesWithThemesAndAspectRatios() {
        let book = Book(title: "Thinking, Fast and Slow", author: "Daniel Kahneman")
        let quote = Quote(text: "Nothing in life is as important as you think it is, while you are thinking about it.", book: book)
        quote.pageNumber = 402
        quote.marginNote = "Focusing illusion"

        for theme in StudioTheme.allCases {
            for aspect in StudioAspectRatio.allCases {
                let card = QuoteCanvasCard(quote: quote, theme: theme, aspectRatio: aspect)
                XCTAssertNotNil(card)
            }
        }
    }

    func testQuoteCanvasCardHandlesVeryLongPassagesWithoutError() {
        let book = Book(title: "Meditations", author: "Marcus Aurelius")
        let longPassage = """
        When you arise in the morning think of what a privilege it is to be alive, to think, to enjoy, to love. \
        The impediment to action advances action. What stands in the way becomes the way. \
        Waste no more time arguing about what a good man should be. Be one. \
        Very little is needed to make a happy life; it is all within yourself in your way of thinking. \
        Look well into thyself; there is a source of strength which will always spring up if thou wilt always look.
        """
        let quote = Quote(text: longPassage, book: book)
        quote.pageNumber = 44
        quote.marginNote = "Core Stoic meditation on dawn and purpose"

        for aspect in StudioAspectRatio.allCases {
            for theme in StudioTheme.allCases {
                let card = QuoteCanvasCard(quote: quote, theme: theme, aspectRatio: aspect)
                XCTAssertNotNil(card)
            }
        }
    }

    func testQuoteCardStudioViewInitializesCleanly() {
        let book = Book(title: "The Odyssey", author: "Homer")
        let quote = Quote(text: "There is a time for many words, and there is also a time for sleep.", book: book)
        quote.pageNumber = 120

        let studioView = QuoteCardStudioView(quote: quote, initialTheme: .warmVellum, initialAspect: .portrait)
        XCTAssertNotNil(studioView)
    }
}
