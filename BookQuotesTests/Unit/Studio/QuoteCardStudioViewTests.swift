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

    func testQuoteCardStudioViewInitializesCleanly() {
        let book = Book(title: "The Odyssey", author: "Homer")
        let quote = Quote(text: "There is a time for many words, and there is also a time for sleep.", book: book)
        quote.pageNumber = 120

        let studioView = QuoteCardStudioView(quote: quote, initialTheme: .warmVellum, initialAspect: .portrait)
        XCTAssertNotNil(studioView)
    }
}
