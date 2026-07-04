import XCTest

@testable import BookQuotes

final class TagRowPresentationTests: XCTestCase {
    func testUsesTagNameAndQuoteCountText() {
        let tag = Tag(name: "strategy", colorName: "green")
        tag.quotes = [
            Quote(text: "first"),
            Quote(text: "second")
        ]

        let presentation = TagRowPresentation(tag: tag)

        XCTAssertEqual(presentation.name, "strategy")
        XCTAssertEqual(presentation.quoteCountText, "2")
    }

    func testUsesConfiguredCollectionColor() {
        let tag = Tag(name: "craft", colorName: "plum")

        let presentation = TagRowPresentation(tag: tag)

        XCTAssertEqual(presentation.collectionColor, .plum)
    }

    func testMapsLegacySystemColorNameOntoPalette() {
        let tag = Tag(name: "strategy", colorName: "purple")

        let presentation = TagRowPresentation(tag: tag)

        XCTAssertEqual(presentation.collectionColor, .plum)
    }

    func testFallsBackToSlateForUnknownColorName() {
        let tag = Tag(name: "ideas", colorName: "unknown")

        let presentation = TagRowPresentation(tag: tag)

        XCTAssertEqual(presentation.collectionColor, .slate)
    }
}
