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

    func testEveryThemeAndFormatPreservesExistingExportGeometry() throws {
        let quote = Quote(text: "A passage worth keeping.", book: Book(title: "A Book", author: "An Author"))
        for theme in StudioTheme.allCases {
            for aspect in StudioAspectRatio.allCases {
                try autoreleasepool {
                    let image = try XCTUnwrap(QuoteStudioExportService.shared.renderImage(
                        quote: quote,
                        theme: theme,
                        aspectRatio: aspect
                    ))
                    // Existing renderer contract: a 400pt canvas at 3x, not the
                    // currently unused 1080px targetSize metadata on the enum.
                    let pixels = try XCTUnwrap(image.cgImage)
                    XCTAssertEqual(pixels.width, 1200, "\(theme) / \(aspect)")
                    XCTAssertEqual(Double(pixels.height), 1200 / Double(aspect.ratioValue), accuracy: 1, "\(theme) / \(aspect)")
                }
            }
        }
    }

    func testHalfSizePreviewMatchesExportPixelsForEveryThemeAndAspect() throws {
        let quote = Quote(text: "A passage with enough words to wrap across several lines, so that preview and export must agree on typography rather than merely sharing a background colour.",
                          book: Book(title: "An illustrated reading notebook", author: "A careful reader"))
        quote.marginNote = "Remember this passage."
        for theme in StudioTheme.allCases {
            for aspect in StudioAspectRatio.allCases {
                try autoreleasepool {
                    let exported = try XCTUnwrap(QuoteStudioExportService.shared.renderImage(
                        quote: quote, theme: theme, aspectRatio: aspect, scale: 1
                    )?.cgImage)
                    let size = CGSize(width: 200, height: 200 / aspect.ratioValue)
                    let preview = QuoteCanvasCard(quote: quote, theme: theme, aspectRatio: aspect)
                        .frame(width: size.width, height: size.height)
                        .environment(\.colorScheme, theme.colorScheme)
                    let renderer = ImageRenderer(content: preview)
                    renderer.scale = 2
                    let pixels = try XCTUnwrap(renderer.uiImage?.cgImage)
                    XCTAssertEqual(pixels.width, exported.width)
                    XCTAssertEqual(pixels.height, exported.height)
                    if theme == .warmVellum && aspect == .square {
                        for (name, image) in [("preview", pixels), ("export", exported)] {
                            let attachment = XCTAttachment(image: UIImage(cgImage: image))
                            attachment.name = name
                            attachment.lifetime = .keepAlways
                            add(attachment)
                        }
                    }
                    let previewData = try XCTUnwrap(pixels.dataProvider?.data) as Data
                    let exportData = try XCTUnwrap(exported.dataProvider?.data) as Data
                    XCTAssertEqual(pixels.bytesPerRow, exported.bytesPerRow)
                    let meanError = zip(previewData, exportData).reduce(0.0) {
                        $0 + abs(Double($1.0) - Double($1.1))
                    } / Double(max(exportData.count, 1))
                    XCTAssertTrue(previewData == exportData, "Preview and export differ for \(theme) / \(aspect); mean channel error \(meanError)")
                }
            }
        }
    }

    func testSafeTransformedPreviewMatchesExportPixels() throws {
        let quote = Quote(text: "The same passage, scale and offset in preview and export.")
        let transform = StudioCanvasTransform(scale: 0.9, normalizedOffset: CGSize(width: 0.01, height: -0.01))
        for aspect in StudioAspectRatio.allCases {
            let size = CGSize(width: 200, height: 200 / aspect.ratioValue)
            let preview = QuoteCanvasCard(quote: quote, theme: .warmVellum, aspectRatio: aspect)
                .frame(width: size.width, height: size.height)
                .scaleEffect(transform.scale)
                .offset(transform.pointOffset(in: size))
                .frame(width: size.width, height: size.height)
                .clipped()
            let renderer = ImageRenderer(content: preview)
            renderer.scale = 2
            let previewPixels = try XCTUnwrap(renderer.uiImage?.cgImage)
            let exportPixels = try XCTUnwrap(QuoteStudioExportService.shared.renderImage(
                quote: quote, theme: .warmVellum, aspectRatio: aspect, transform: transform, scale: 1
            )?.cgImage)
            XCTAssertEqual(previewPixels.width, exportPixels.width)
            XCTAssertEqual(previewPixels.height, exportPixels.height)
            let previewData = try XCTUnwrap(previewPixels.dataProvider?.data) as Data
            let exportData = try XCTUnwrap(exportPixels.dataProvider?.data) as Data
            XCTAssertTrue(previewData == exportData, "Transformed preview differs for \(aspect)")
        }
    }

    func testLongPassageAndLongNoteCannotSilentlyExportCroppedImages() {
        let service = QuoteStudioExportService.shared
        let quote = Quote(text: String(repeating: "A complete passage must remain readable. ", count: 300))
        for aspect in StudioAspectRatio.allCases {
            XCTAssertNotNil(service.contentIssue(quote: quote, theme: .warmVellum, aspectRatio: aspect))
            XCTAssertNil(service.renderImage(quote: quote, theme: .warmVellum, aspectRatio: aspect))
        }
        quote.text = "A short passage."
        quote.marginNote = String(repeating: "A full note must not be truncated. ", count: 300)
        XCTAssertNotNil(service.contentIssue(quote: quote, theme: .warmVellum, aspectRatio: .story))
        XCTAssertNil(service.renderImage(quote: quote, theme: .warmVellum, aspectRatio: .story))
        XCTAssertTrue(service.generateObsidianMarkdown(quote: quote).contains(quote.marginNote!))
    }

    func testOversizedAttributionMustFitWithoutEllipsis() {
        let quote = Quote(text: "A short passage.", book: Book(
            title: String(repeating: "A very long title ", count: 200),
            author: "A reader"
        ))
        XCTAssertNotNil(QuoteStudioExportService.shared.contentIssue(quote: quote, theme: .darkLinen, aspectRatio: .square))
    }

    func testDeniedPhotosPermissionDoesNotInvokeWriter() async {
        var writes = 0
        let service = QuoteStudioExportService(authorizePhotos: { .denied }, writePhoto: { _ in writes += 1 })
        do {
            try await service.saveImageToPhotos(quote: Quote(text: "A passage."), theme: .warmVellum, aspectRatio: .square)
            XCTFail("Denied permission must not report success")
        } catch {
            XCTAssertEqual(writes, 0)
            XCTAssertTrue(error.localizedDescription.contains("Settings"))
            XCTAssertTrue(error.localizedDescription.contains("Share Image"))
        }
    }

    func testPhotoWriteFailureCanRetryAndUsesFrozenImageAcrossAuthorization() async throws {
        enum WriteFailure: Error { case rejected }
        let quote = Quote(text: "Original passage.")
        let original = try XCTUnwrap(QuoteStudioExportService.shared.renderImage(
            quote: quote, theme: .warmVellum, aspectRatio: .square
        )?.pngData())
        var writes = 0
        var firstImage: Data?
        let service = QuoteStudioExportService(authorizePhotos: {
            quote.text = "Edited while permission is pending."
            return .authorized
        }, writePhoto: { image in
            writes += 1
            if writes == 1 {
                firstImage = image.pngData()
                throw WriteFailure.rejected
            }
        })
        do {
            try await service.saveImageToPhotos(quote: quote, theme: .warmVellum, aspectRatio: .square)
            XCTFail("A failed write must propagate failure")
        } catch {
            XCTAssertTrue(error is WriteFailure)
        }
        XCTAssertEqual(firstImage, original, "Authorization must not replace the in-flight export snapshot")
        try await service.saveImageToPhotos(quote: quote, theme: .warmVellum, aspectRatio: .square)
        XCTAssertEqual(writes, 2)
    }

    func testClipboardFailureIsReportedAndCanRetry() {
        var writes = 0
        let service = QuoteStudioExportService(writeClipboard: { _ in
            writes += 1
            return writes > 1
        })
        let quote = Quote(text: "A passage.")
        XCTAssertFalse(service.copyImageToClipboard(quote: quote, theme: .warmVellum, aspectRatio: .square))
        XCTAssertTrue(service.copyImageToClipboard(quote: quote, theme: .warmVellum, aspectRatio: .square))
        XCTAssertEqual(writes, 2)
    }

    func testStudioSelectionDoesNotSilentlyChangeWhenReorderedOrDeleted() {
        let first = Quote(text: "First")
        let second = Quote(text: "Second")
        XCTAssertEqual(StudioTab.selectedPassage(in: [first, second], id: nil)?.id, first.id)
        XCTAssertEqual(StudioTab.selectedPassage(in: [second, first], id: first.id)?.id, first.id)
        XCTAssertNil(StudioTab.selectedPassage(in: [second], id: first.id))
        XCTAssertNil(StudioTab.selectedPassage(in: [], id: first.id))
    }

    func testCroppingAndInvalidTransformsHaveAnExplicitResetPath() {
        let service = QuoteStudioExportService.shared
        for aspect in StudioAspectRatio.allCases {
            XCTAssertNil(service.transformIssue(.identity, aspectRatio: aspect))
            for transform in [StudioCanvasTransform(scale: 2, normalizedOffset: .zero),
                              StudioCanvasTransform(scale: 1, normalizedOffset: CGSize(width: 1, height: 0)),
                              StudioCanvasTransform(scale: .nan, normalizedOffset: .zero)] {
                XCTAssertTrue(service.transformIssue(transform, aspectRatio: aspect)?.contains("Reset") == true)
            }
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
                scale: 0.9,
                normalizedOffset: CGSize(width: 0.01, height: -0.01)
            ),
            scale: 1.0
        ))

        XCTAssertEqual(identity.size, transformed.size)
        XCTAssertNotEqual(identity.pngData(), transformed.pngData())
    }
}
