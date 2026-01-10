import Foundation

struct JSONFormatter: QuoteFormatter {
    func format(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult {
        guard !quotes.isEmpty else {
            throw ExportError.emptyQuotes
        }

        let payload = buildPayload(quotes: quotes, options: options)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(payload)
        let filename = "BookQuotes_Export_\(ISO8601DateFormatter().string(from: Date())).json"
        let url = try ExportFileWriter.saveData(data, filename: filename)
        return .file(url, filename: filename)
    }

    private func buildPayload(quotes: [Quote], options: ExportOptions) -> ExportPayload {
        if options.groupByBook {
            let grouped = Dictionary(grouping: quotes) { $0.book?.id }
            let books = grouped.values.map { quotes in
                ExportBook(
                    id: quotes.first?.book?.id,
                    title: quotes.first?.book?.title,
                    author: quotes.first?.book?.author,
                    isbn: quotes.first?.book?.isbn,
                    quotes: quotes.map { exportQuote(from: $0, options: options) }
                )
            }

            return ExportPayload(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                groupedByBook: true,
                books: books.sorted { ($0.title ?? "") < ($1.title ?? "") },
                quotes: nil
            )
        }

        return ExportPayload(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            groupedByBook: false,
            books: nil,
            quotes: quotes.map { exportQuote(from: $0, options: options) }
        )
    }

    private func exportQuote(from quote: Quote, options: ExportOptions) -> ExportQuote {
        let includeMetadata = options.includeMetadata

        return ExportQuote(
            text: quote.text,
            pageNumber: options.includePageNumbers ? quote.pageNumber : nil,
            marginNote: options.includeMarginNotes ? quote.marginNote : nil,
            markingType: includeMetadata ? (quote.customMarkingDefinition?.name ?? quote.markingType.displayName) : nil,
            confidence: includeMetadata ? quote.confidence : nil,
            capturedAt: includeMetadata ? options.formattedDate(quote.captureDate) : nil,
            bookTitle: includeMetadata ? quote.book?.title : nil,
            bookAuthor: includeMetadata ? quote.book?.author : nil
        )
    }
}

private struct ExportPayload: Codable {
    let generatedAt: String
    let groupedByBook: Bool
    let books: [ExportBook]?
    let quotes: [ExportQuote]?
}

private struct ExportBook: Codable {
    let id: UUID?
    let title: String?
    let author: String?
    let isbn: String?
    let quotes: [ExportQuote]
}

private struct ExportQuote: Codable {
    let text: String
    let pageNumber: Int?
    let marginNote: String?
    let markingType: String?
    let confidence: Double?
    let capturedAt: String?
    let bookTitle: String?
    let bookAuthor: String?
}
