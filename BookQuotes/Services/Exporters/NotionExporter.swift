import Foundation

struct NotionExporter {
    func export(_ quotes: [Quote], options: ExportOptions) async throws -> ExportResult {
        guard !quotes.isEmpty else {
            throw ExportError.emptyQuotes
        }

        return .apiError(message: "Notion export is not implemented yet.")
    }
}
