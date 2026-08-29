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

    /// Renders a quote card to a high-resolution UIImage.
    func renderImage(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio,
        scale: CGFloat = 3.0
    ) -> UIImage? {
        let cardWidth: CGFloat = 400
        let cardHeight: CGFloat = cardWidth / aspectRatio.ratioValue

        let card = QuoteCanvasCard(
            quote: quote,
            theme: theme,
            aspectRatio: aspectRatio
        )
        .frame(width: cardWidth, height: cardHeight)
        .environment(\.colorScheme, theme.colorScheme)

        let renderer = ImageRenderer(content: card)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: cardWidth, height: cardHeight)
        return renderer.uiImage
    }

    // MARK: - Copy Image to Clipboard

    /// Copies the rendered quote card image to the system pasteboard.
    @discardableResult
    func copyImageToClipboard(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio
    ) -> Bool {
        guard let image = renderImage(quote: quote, theme: theme, aspectRatio: aspectRatio) else {
            return false
        }
        UIPasteboard.general.image = image
        HapticManager.notification(.success)
        return true
    }

    // MARK: - Save to Photo Library

    /// Saves the rendered card to the user's photo library.
    func saveImageToPhotos(
        quote: Quote,
        theme: StudioTheme,
        aspectRatio: StudioAspectRatio
    ) async throws {
        guard let image = renderImage(quote: quote, theme: theme, aspectRatio: aspectRatio) else {
            throw ExportError.writeFailed
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(throwing: ExportError.writeFailed)
                    return
                }

                UIImageWriteToSavedPhotosAlbum(
                    image,
                    PhotoSaveTarget { success, error in
                        if success {
                            HapticManager.notification(.success)
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: error ?? ExportError.writeFailed)
                        }
                    },
                    #selector(PhotoSaveTarget.image(_:didFinishSavingWithError:contextInfo:)),
                    nil
                )
            }
        }
    }

    // MARK: - Obsidian Export

    /// Generates Obsidian-compatible markdown with YAML frontmatter.
    func generateObsidianMarkdown(quote: Quote) -> String {
        var content = "---\n"
        if let book = quote.book {
            content += "title: \"\(book.title)\"\n"
            content += "author: \"\(book.author)\"\n"
            if let isbn = book.isbn {
                content += "isbn: \"\(isbn)\"\n"
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
            content += "  - \(tag.name.lowercased().replacingOccurrences(of: " ", with: "-"))\n"
        }
        content += "---\n\n"

        if let book = quote.book {
            content += "# \(book.title)\n"
            content += "*by \(book.author)*\n\n"
        }

        content += "> \(quote.text)\n\n"

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

    /// Generates Notion-compatible block markdown.
    func generateNotionMarkdown(quote: Quote) -> String {
        var output = ""
        if let book = quote.book {
            output += "# \(book.title)\n\n"
            output += "| Property | Value |\n"
            output += "|---|---|\n"
            output += "| Author | \(book.author) |\n"
            output += "| Status | \(book.status.displayName) |\n"
            if let page = quote.pageNumber {
                output += "| Page | \(page) |\n"
            }
            output += "\n---\n\n"
        }

        output += "> 💬 \(quote.text)\n"

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
}

// MARK: - PhotoSaveTarget Helper

private final class PhotoSaveTarget: NSObject {
    private let completion: (Bool, Error?) -> Void

    init(completion: @escaping (Bool, Error?) -> Void) {
        self.completion = completion
        super.init()
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion(error == nil, error)
    }
}
