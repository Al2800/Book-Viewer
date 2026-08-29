import Foundation

struct NotionExporter: QuoteFormatter {
    func export(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult {
        return try await format(quotes, options: options)
    }

    func format(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult {
        guard !quotes.isEmpty else {
            throw ExportError.emptyQuotes
        }

        var output = ""
        let grouped = Dictionary(grouping: quotes) { $0.book?.id }

        for (_, bookQuotes) in grouped {
            if let book = bookQuotes.first?.book {
                output += "# \(book.title)\n\n"
                output += "| Property | Value |\n"
                output += "|---|---|\n"
                output += "| Author | \(book.author) |\n"
                output += "| Status | \(book.status.displayName) |\n"
                output += "| Quotes | \(bookQuotes.count) |\n\n"
                output += "---\n\n"
            }

            output += "## Quotes\n\n"
            let sortedQuotes = bookQuotes.sorted { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
            for quote in sortedQuotes {
                output += "> 💬 \(quote.text)\n"
                var metadata: [String] = []
                if let page = quote.pageNumber, options.includePageNumbers {
                    metadata.append("Page \(page)")
                }
                let marking = quote.customMarkingDefinition?.name ?? quote.markingType.displayName
                if !marking.isEmpty {
                    metadata.append(marking)
                }
                if options.includeMetadata && !metadata.isEmpty {
                    output += ">\n"
                    output += "> *\(metadata.joined(separator: " • "))*\n\n"
                } else {
                    output += "\n"
                }

                if options.includeMarginNotes, let note = quote.marginNote, !note.isEmpty {
                    output += "📝 **My note:** \(note)\n\n"
                }
            }
        }

        let filename = "BookQuotes_Notion_\(ISO8601DateFormatter().string(from: Date())).md"
        let url = try ExportFileWriter.saveText(output, filename: filename)
        return .file(url, filename: filename)
    }
}
