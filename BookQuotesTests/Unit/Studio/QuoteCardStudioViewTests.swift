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

    func testStudioCanvasTransformRoundTripsPointOffset() {
        let cardSize = CGSize(width: 400, height: 500)
        let pointOffset = CGSize(width: 40, height: -75)

        let transform = StudioCanvasTransform.normalized(
            scale: 1.35,
            pointOffset: pointOffset,
            cardSize: cardSize
        )

        XCTAssertEqual(transform.scale, 1.35, accuracy: 0.0001)
        XCTAssertEqual(transform.normalizedOffset.width, 0.1, accuracy: 0.0001)
        XCTAssertEqual(transform.normalizedOffset.height, -0.15, accuracy: 0.0001)
        XCTAssertEqual(transform.pointOffset(in: cardSize).width, pointOffset.width, accuracy: 0.0001)
        XCTAssertEqual(transform.pointOffset(in: cardSize).height, pointOffset.height, accuracy: 0.0001)
    }

    func testAspectFitGeometryCentersPortraitImageAndMapsNormalizedBox() {
        let contentSize = CGSize(width: 100, height: 200)
        let containerSize = CGSize(width: 300, height: 300)

        let fitted = AspectFitGeometry.fittedRect(
            contentSize: contentSize,
            in: containerSize
        )
        XCTAssertEqual(fitted, CGRect(x: 75, y: 0, width: 150, height: 300))

        let mapped = AspectFitGeometry.scaleNormalizedRect(
            CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.25),
            contentSize: contentSize,
            containerSize: containerSize
        )
        XCTAssertEqual(mapped.origin.x, 90, accuracy: 0.0001)
        XCTAssertEqual(mapped.origin.y, 60, accuracy: 0.0001)
        XCTAssertEqual(mapped.width, 75, accuracy: 0.0001)
        XCTAssertEqual(mapped.height, 75, accuracy: 0.0001)
    }

    func testAspectFitGeometryReturnsZeroForInvalidSizes() {
        XCTAssertEqual(
            AspectFitGeometry.fittedRect(
                contentSize: .zero,
                in: CGSize(width: 300, height: 300)
            ),
            .zero
        )
        XCTAssertEqual(
            AspectFitGeometry.scaleNormalizedRect(
                CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5),
                contentSize: CGSize(width: 100, height: 200),
                containerSize: .zero
            ),
            .zero
        )
    }
}
