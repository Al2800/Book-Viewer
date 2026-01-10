import Foundation

protocol QuoteFormatter {
    func format(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult
}

struct QuoteGroup {
    let book: Book?
    let quotes: [Quote]
}
