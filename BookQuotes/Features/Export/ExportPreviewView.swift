import SwiftUI

struct ExportPreviewView: View {
    let quotes: [Quote]
    let format: ExportFormat
    let options: ExportOptions

    var body: some View {
        Section("Preview") {
            Text(previewText)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var previewText: String {
        ExportPreviewBuilder.preview(
            quotes: quotes,
            format: format,
            options: options
        )
    }
}

enum ExportPreviewBuilder {
    static func preview(
        quotes: [Quote],
        format: ExportFormat,
        options: ExportOptions
    ) -> String {
        guard let sample = quotes.first else {
            return "No quotes available for preview."
        }

        switch format {
        case .markdown:
            return markdownPreview(quote: sample, options: options)
        case .plainText:
            return plainTextPreview(quote: sample, options: options)
        case .json:
            return jsonPreview(quote: sample, options: options)
        case .notion:
            return "Notion export will send your quotes to a Notion database."
        case .obsidian:
            return obsidianPreview(quote: sample, options: options)
        }
    }

    private static func markdownPreview(quote: Quote, options: ExportOptions) -> String {
        var output = "> \(quote.text)\n\n"

        if options.includeMetadata {
            var attributionParts: [String] = []
            if let page = quote.pageNumber, options.includePageNumbers {
                attributionParts.append("p. \(page)")
            }
            let markingName = quote.customMarkingDefinition?.name ?? quote.markingType.displayName
            attributionParts.append(markingName)
            output += "*\(attributionParts.joined(separator: " • "))*\n"
        }

        if options.includeMarginNotes, let note = quote.marginNote {
            output += "\n**Note:** \(note)\n"
        }

        return output
    }

    private static func plainTextPreview(quote: Quote, options: ExportOptions) -> String {
        var lines: [String] = [quote.text]

        if options.includeMetadata {
            var metadataParts: [String] = []
            if let page = quote.pageNumber, options.includePageNumbers {
                metadataParts.append("p. \(page)")
            }
            metadataParts.append(quote.customMarkingDefinition?.name ?? quote.markingType.displayName)

            if let book = quote.book {
                metadataParts.append("\(book.title) — \(book.author)")
            }

            if !metadataParts.isEmpty {
                lines.append("(" + metadataParts.joined(separator: " • ") + ")")
            }
        }

        if options.includeMarginNotes, let note = quote.marginNote {
            lines.append("Note: \(note)")
        }

        return lines.joined(separator: "\n")
    }

    private static func jsonPreview(quote: Quote, options: ExportOptions) -> String {
        var dict: [String: Any] = ["text": quote.text]

        if options.includePageNumbers, let page = quote.pageNumber {
            dict["pageNumber"] = page
        }

        if options.includeMarginNotes, let note = quote.marginNote {
            dict["marginNote"] = note
        }

        if options.includeMetadata {
            dict["markingType"] = quote.customMarkingDefinition?.name ?? quote.markingType.displayName
            dict["confidence"] = quote.confidence
            dict["capturedAt"] = options.formattedDate(quote.captureDate)
            dict["bookTitle"] = quote.book?.title
            dict["bookAuthor"] = quote.book?.author
        }

        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
           let string = String(data: data, encoding: .utf8) {
            return string
        }

        return "{ \"text\": \"\(quote.text)\" }"
    }

    private static func obsidianPreview(quote: Quote, options: ExportOptions) -> String {
        var output = "---\n"
        output += "title: \"Sample Book\"\n"
        output += "author: \"Sample Author\"\n"
        output += "type: book-quotes\n"
        output += "---\n\n"
        output += "# Sample Book\n"
        output += "*by Sample Author*\n\n"
        output += "> \(quote.text)\n\n"

        if options.includeMetadata {
            var metadataLine = ""
            if let page = quote.pageNumber, options.includePageNumbers {
                metadataLine += "Page \(page)"
            }

            let marking = quote.customMarkingDefinition?.name ?? quote.markingType.displayName
            if !marking.isEmpty {
                if !metadataLine.isEmpty {
                    metadataLine += " • "
                }
                metadataLine += marking
            }

            if !metadataLine.isEmpty {
                output += "\(metadataLine)\n\n"
            }
        }

        if options.includeMarginNotes, let note = quote.marginNote {
            output += "**Note:** \(note)\n\n"
        }

        return output
    }
}
