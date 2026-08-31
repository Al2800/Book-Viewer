import XCTest
import SwiftUI
@testable import BookQuotes

@MainActor
final class QuoteStudioExportServiceTests: XCTestCase {
    func testGenerateObsidianMarkdownContainsFrontmatterAndQuotes() {
        let book = Book(title: "Meditations", author: "Marcus Aurelius", isbn: "9780140449334")
        let quote = Quote(text: "You have power over your mind - not outside events.", book: book)
        quote.pageNumber = 42
        quote.marginNote = "Key stoic insight"

        let markdown = QuoteStudioExportService.shared.generateObsidianMarkdown(quote: quote)

        XCTAssertTrue(markdown.contains("---"), "Must contain frontmatter header")
        XCTAssertTrue(markdown.contains("title: \"Meditations\""))
        XCTAssertTrue(markdown.contains("author: \"Marcus Aurelius\""))
        XCTAssertTrue(markdown.contains("isbn: \"9780140449334\""))
        XCTAssertTrue(markdown.contains("page: 42"))
        XCTAssertTrue(markdown.contains("You have power over your mind"))
        XCTAssertTrue(markdown.contains("Key stoic insight"))
    }

    func testGenerateNotionMarkdownContainsPropertiesTableAndCallout() {
        let book = Book(title: "Atomic Habits", author: "James Clear")
        let quote = Quote(text: "Every action you take is a vote for the person you wish to become.", book: book)
        quote.pageNumber = 15
        quote.marginNote = "Habit identity"

        let markdown = QuoteStudioExportService.shared.generateNotionMarkdown(quote: quote)

        XCTAssertTrue(markdown.contains("# Atomic Habits"))
        XCTAssertTrue(markdown.contains("| Property | Value |"))
        XCTAssertTrue(markdown.contains("| Author | James Clear |"))
        XCTAssertTrue(markdown.contains("> 💬 Every action you take"))
        XCTAssertTrue(markdown.contains("Page 15"))
        XCTAssertTrue(markdown.contains("📝 **My note:** Habit identity"))
    }

    func testObsidianMarkdownEscapesQuotedAndMultilineYamlValues() {
        let book = Book(
            title: "A \"Quoted\"\nTitle",
            author: "Reader \\ Writer",
            isbn: "9780000000002"
        )
        let quote = Quote(text: "First line\nSecond line", book: book)

        let markdown = QuoteStudioExportService.shared.generateObsidianMarkdown(quote: quote)

        XCTAssertTrue(markdown.contains("title: \"A \\\"Quoted\\\"\\nTitle\""))
        XCTAssertTrue(markdown.contains("author: \"Reader \\\\ Writer\""))
        XCTAssertTrue(markdown.contains("> First line\n> Second line"))
    }

    func testNotionMarkdownEscapesTablePipesAndPreservesMultilineQuote() {
        let book = Book(title: "Systems", author: "A | B")
        let quote = Quote(text: "First line\nSecond line", book: book)

        let markdown = QuoteStudioExportService.shared.generateNotionMarkdown(quote: quote)

        XCTAssertTrue(markdown.contains("| Author | A \\| B |"))
        XCTAssertTrue(markdown.contains("> 💬 First line\n> Second line"))
    }

    func testRenderImageProducesValidUIImage() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        let quote = Quote(text: "Fear is the mind-killer.", book: book)
        quote.pageNumber = 8

        let image = QuoteStudioExportService.shared.renderImage(
            quote: quote,
            theme: .darkLinen,
            aspectRatio: .square,
            scale: 1.0
        )

        XCTAssertNotNil(image, "Image rendering should produce a non-nil UIImage")
        if let image {
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
        }
    }

    func testRenderImageAppliesCanvasTransformWithoutChangingOutputSize() throws {
        let book = Book(title: "Dune", author: "Frank Herbert")
        let quote = Quote(text: "Fear is the mind-killer.", book: book)
        let service = QuoteStudioExportService.shared

        let identity = try XCTUnwrap(service.renderImage(
            quote: quote,
            theme: .darkLinen,
            aspectRatio: .square,
            scale: 1.0
        ))
        let transformed = try XCTUnwrap(service.renderImage(
            quote: quote,
            theme: .darkLinen,
            aspectRatio: .square,
            transform: StudioCanvasTransform(
                scale: 1.4,
                normalizedOffset: CGSize(width: 0.1, height: -0.08)
            ),
            scale: 1.0
        ))

        XCTAssertEqual(identity.size, transformed.size)
        XCTAssertNotEqual(identity.pngData(), transformed.pngData())
    }
}
