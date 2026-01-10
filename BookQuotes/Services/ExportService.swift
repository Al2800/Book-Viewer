import Foundation

// MARK: - Export Service

actor ExportService {
    func export(
        quotes: [Quote],
        format: ExportFormat,
        options: ExportOptions = ExportOptions()
    ) async throws -> ExportResult {
        switch format {
        case .markdown:
            return try await MarkdownFormatter().format(quotes, options: options)
        case .plainText:
            return try await PlainTextFormatter().format(quotes, options: options)
        case .json:
            return try await JSONFormatter().format(quotes, options: options)
        case .notion:
            return try await NotionExporter().export(quotes, options: options)
        case .obsidian:
            return try await ObsidianFormatter().format(quotes, options: options)
        }
    }
}
