import Foundation

struct ObsidianFormatter: QuoteFormatter {
    func format(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult {
        guard !quotes.isEmpty else {
            throw ExportError.emptyQuotes
        }

        let grouped = Dictionary(grouping: quotes) { $0.book?.id }
        var files: [(filename: String, content: String)] = []

        for bookQuotes in grouped.values {
            guard let book = bookQuotes.first?.book else { continue }

            var content = ""
            content += "---\n"
            content += "title: \"\(book.title)\"\n"
            content += "author: \"\(book.author)\"\n"
            if let isbn = book.isbn {
                content += "isbn: \"\(isbn)\"\n"
            }
            content += "type: book-quotes\n"
            content += "quote_count: \(bookQuotes.count)\n"
            content += "date_exported: \(Date().ISO8601Format())\n"
            content += "tags:\n"
            content += "  - book-quotes\n"
            content += "  - reading\n"
            content += "---\n\n"

            content += "# \(book.title)\n"
            content += "*by \(book.author)*\n\n"

            let sortedQuotes = bookQuotes.sorted { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
            for quote in sortedQuotes {
                content += "## \n\n"
                content += "> \(quote.text)\n\n"

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
                        content += "\(metadataLine)\n\n"
                    }
                }

                if options.includeMarginNotes, let note = quote.marginNote {
                    content += "**Note:** \(note)\n\n"
                }
            }

            let filename = ExportFileWriter.sanitizeFilename("\(book.title) - Quotes.md")
            files.append((filename: filename, content: content))
        }

        return try ExportFileWriter.packageTextFiles(files, bundleName: "BookQuotes_Obsidian_Export")
    }
}
