import Foundation

struct PlainTextFormatter: QuoteFormatter {
    func format(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult {
        guard !quotes.isEmpty else {
            throw ExportError.emptyQuotes
        }

        var output = ""
        let groups = groupedQuotes(quotes)

        if options.groupByBook {
            for group in groups {
                if let book = group.book {
                    output += "\(book.title)\n"
                    output += "by \(book.author)\n\n"
                }

                for quote in group.quotes {
                    output += formatQuote(quote, options: options)
                    output += "\n\n"
                }
            }
        } else {
            for quote in quotes {
                output += formatQuote(quote, options: options)
                output += "\n\n"
            }
        }

        let filename = "BookQuotes_Export_\(ISO8601DateFormatter().string(from: Date())).txt"
        let url = try ExportFileWriter.saveText(output, filename: filename)
        return .file(url, filename: filename)
    }

    private func formatQuote(_ quote: Quote, options: ExportOptions) -> String {
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

    private func groupedQuotes(_ quotes: [Quote]) -> [QuoteGroup] {
        let grouped = Dictionary(grouping: quotes) { $0.book?.id }
        let groups = grouped.values.map { quotes in
            QuoteGroup(book: quotes.first?.book, quotes: quotes)
        }
        return groups.sorted { ($0.book?.title ?? "") < ($1.book?.title ?? "") }
    }
}
