import SwiftUI
import UIKit
import Photos

// MARK: - QuoteStudioExportService

/// Export service for high-resolution images, Obsidian markdown, and Notion markdown.
@MainActor
final class QuoteStudioExportService {
    static let shared = QuoteStudioExportService()

    private init() {}

    // MARK: - Image Rendering

    /// Renders the same scale and normalized offset shown on the interactive canvas.
    func renderImage(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio,
        transform: StudioCanvasTransform = .identity,
        scale: CGFloat = 3.0
    ) -> UIImage? {
        let cardWidth: CGFloat = 400
        let cardHeight: CGFloat = cardWidth / aspectRatio.ratioValue
        let cardSize = CGSize(width: cardWidth, height: cardHeight)

        let canvas = ZStack {
            QuoteCanvasCard(
                quote: quote,
                theme: theme,
                aspectRatio: aspectRatio
            )
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(transform.scale)
            .offset(transform.pointOffset(in: cardSize))
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipped()
        .environment(\.colorScheme, theme.colorScheme)

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: cardWidth, height: cardHeight)
        return renderer.uiImage
    }

    // MARK: - Copy Image to Clipboard

    @discardableResult
    func copyImageToClipboard(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio,
        transform: StudioCanvasTransform = .identity
    ) -> Bool {
        guard let image = renderImage(
            quote: quote,
            theme: theme,
            aspectRatio: aspectRatio,
            transform: transform
        ) else {
            return false
        }
        UIPasteboard.general.image = image
        HapticManager.notification(.success)
        return true
    }

    // MARK: - Save to Photo Library

    func saveImageToPhotos(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio,
        transform: StudioCanvasTransform = .identity
    ) async throws {
        guard let image = renderImage(
            quote: quote,
            theme: theme,
            aspectRatio: aspectRatio,
            transform: transform
        ) else {
            throw ExportError.writeFailed
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.writeFailed
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
        HapticManager.notification(.success)
    }

    // MARK: - Obsidian Export

    func generateObsidianMarkdown(quote: Quote) -> String {
        var content = "---\n"
        if let book = quote.book {
            content += "title: \"\(yamlEscaped(book.title))\"\n"
            content += "author: \"\(yamlEscaped(book.author))\"\n"
            if let isbn = book.isbn {
                content += "isbn: \"\(yamlEscaped(isbn))\"\n"
            }
        }
        content += "type: book-quote\n"
        if let page = quote.pageNumber {
            content += "page: \(page)\n"
        }
        content += "date_exported: \(ISO8601DateFormatter().string(from: Date()))\n"
        content += "tags:\n"
        content += "  - book-quotes\n"
        content += "  - reading\n"
        for tag in quote.tags {
            let value = markdownTag(tag.name)
            if !value.isEmpty {
                content += "  - \(value)\n"
            }
        }
        content += "---\n\n"

        if let book = quote.book {
            content += "# \(book.title)\n"
            content += "*by \(book.author)*\n\n"
        }

        content += markdownBlockquote(quote.text) + "\n\n"

        var metadataParts: [String] = []
        if let page = quote.pageNumber {
            metadataParts.append("Page \(page)")
        }
        let marking = quote.customMarkingDefinition?.name ?? quote.markingType.displayName
        if !marking.isEmpty {
            metadataParts.append(marking)
        }
        if !metadataParts.isEmpty {
            content += "*\(metadataParts.joined(separator: " • "))*\n\n"
        }

        if let note = quote.marginNote, !note.isEmpty {
            content += "**Note:** \(note)\n\n"
        }

        return content
    }

    // MARK: - Notion Export

    func generateNotionMarkdown(quote: Quote) -> String {
        var output = ""
        if let book = quote.book {
            output += "# \(book.title)\n\n"
            output += "| Property | Value |\n"
            output += "|---|---|\n"
            output += "| Author | \(markdownTableValue(book.author)) |\n"
            output += "| Status | \(markdownTableValue(book.status.displayName)) |\n"
            if let page = quote.pageNumber {
                output += "| Page | \(page) |\n"
            }
            output += "\n---\n\n"
        }

        output += markdownBlockquote("💬 \(quote.text)") + "\n"

        var metadata: [String] = []
        if let page = quote.pageNumber {
            metadata.append("Page \(page)")
        }
        let marking = quote.customMarkingDefinition?.name ?? quote.markingType.displayName
        if !marking.isEmpty {
            metadata.append(marking)
        }
        if !metadata.isEmpty {
            output += ">\n"
            output += "> *\(metadata.joined(separator: " • "))*\n\n"
        } else {
            output += "\n"
        }

        if let note = quote.marginNote, !note.isEmpty {
            output += "📝 **My note:** \(note)\n\n"
        }

        return output
    }

    // MARK: - Escaping

    private func yamlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\n")
    }

    private func markdownTableValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\r\n", with: "<br>")
            .replacingOccurrences(of: "\n", with: "<br>")
            .replacingOccurrences(of: "\r", with: "<br>")
    }

    private func markdownBlockquote(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "> \($0)" }
            .joined(separator: "\n")
    }

    private func markdownTag(_ value: String) -> String {
        let lowered = value.lowercased()
        let allowed = lowered.map { character -> Character in
            character.isLetter || character.isNumber ? character : "-"
        }
        return String(allowed)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
    }
}
