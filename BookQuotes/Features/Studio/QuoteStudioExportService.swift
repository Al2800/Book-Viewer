import SwiftUI
import UIKit
import Photos

// MARK: - QuoteStudioExportService

/// Export service for high-resolution images, Obsidian markdown, and Notion markdown.
@MainActor
final class QuoteStudioExportService {
    static let shared = QuoteStudioExportService()

    enum PhotoAccessError: LocalizedError {
        case denied

        var errorDescription: String? {
            "Photos access is not allowed. Enable Add Photos access for BookQuotes in Settings, or use Share Image."
        }
    }

    private let authorizePhotos: () async -> PHAuthorizationStatus
    private let writePhoto: (UIImage) async throws -> Void
    private let writeClipboard: (UIImage) -> Bool

    init(
        authorizePhotos: @escaping () async -> PHAuthorizationStatus = {
            await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        },
        writePhoto: @escaping (UIImage) async throws -> Void = { image in
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        },
        writeClipboard: @escaping (UIImage) -> Bool = { image in
            UIPasteboard.general.image = image
            return UIPasteboard.general.hasImages
        }
    ) {
        self.authorizePhotos = authorizePhotos
        self.writePhoto = writePhoto
        self.writeClipboard = writeClipboard
    }

    // MARK: - Image Validation

    /// Measure the actual shared SwiftUI content, not character-count estimates.
    func contentIssue(quote: Quote, theme: StudioTheme, aspectRatio: StudioAspectRatio) -> String? {
        let card = QuoteCanvasCard(quote: quote, theme: theme, aspectRatio: aspectRatio)
        let width = QuoteCanvasCard.renderingWidth
        let content = card.content
            .environment(\.displayScale, QuoteCanvasCard.renderingDisplayScale)
            .environment(\.dynamicTypeSize, .large)
            .environment(\.colorScheme, theme.colorScheme)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
        let host = UIHostingController(rootView: content)
        let required = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        guard required.height.isFinite, required.height <= width / aspectRatio.ratioValue else {
            return "This passage, note and attribution do not fit this card. Choose a taller aspect or another passage, or export Markdown. Your passage is unchanged."
        }
        return nil
    }

    /// Conservative content bounds protect text/attribution even when decorative
    /// borders extend outside the crop. No confidence or character-count policy.
    func transformIssue(_ transform: StudioCanvasTransform, aspectRatio: StudioAspectRatio) -> String? {
        let width = QuoteCanvasCard.renderingWidth
        let height = width / aspectRatio.ratioValue
        let padding = QuoteCanvasCard.padding(for: aspectRatio)
        let scale = transform.scale
        let offset = transform.pointOffset(in: CGSize(width: width, height: height))
        guard scale.isFinite, scale > 0, offset.width.isFinite, offset.height.isFinite else {
            return "The card adjustment is invalid. Use Adjust → Center and Reset before exporting an image."
        }
        let content = CGRect(
            x: (padding - width / 2) * scale + width / 2 + offset.width,
            y: (padding - height / 2) * scale + height / 2 + offset.height,
            width: (width - padding * 2) * scale,
            height: (height - padding * 2) * scale
        )
        guard CGRect(x: 0, y: 0, width: width, height: height).contains(content) else {
            return "This adjustment may crop passage text or attribution. Use Adjust → Center and Reset, or zoom out and centre the card."
        }
        return nil
    }

    // MARK: - Image Rendering

    /// Renders the same scale and normalized offset shown on the interactive canvas.
    func renderImage(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio,
        transform: StudioCanvasTransform = .identity,
        scale: CGFloat = 3.0
    ) -> UIImage? {
        guard scale.isFinite, scale > 0,
              transformIssue(transform, aspectRatio: aspectRatio) == nil,
              contentIssue(quote: quote, theme: theme, aspectRatio: aspectRatio) == nil else {
            return nil
        }
        let cardWidth = QuoteCanvasCard.renderingWidth
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
        guard writeClipboard(image) else { return false }
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

        let status = await authorizePhotos()
        guard status == .authorized || status == .limited else {
            throw PhotoAccessError.denied
        }

        try await writePhoto(image)
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
