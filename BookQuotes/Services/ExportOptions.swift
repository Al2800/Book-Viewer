import Foundation

// MARK: - Export Types

enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown = "Markdown"
    case plainText = "Plain Text"
    case json = "JSON"
    case notion = "Notion"
    case obsidian = "Obsidian"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .markdown, .obsidian:
            return "md"
        case .plainText:
            return "txt"
        case .json:
            return "json"
        case .notion:
            return ""
        }
    }
}

struct ExportOptions: Equatable, Codable {
    var includeMetadata: Bool = true
    var groupByBook: Bool = true
    var includePageNumbers: Bool = true
    var includeMarginNotes: Bool = true
    var dateFormat: String = "yyyy-MM-dd"
}

enum ExportResult: Equatable {
    case file(URL, filename: String)
    case apiSuccess(message: String)
    case apiError(message: String)
}

enum ExportError: LocalizedError {
    case emptyQuotes
    case encodingFailed
    case writeFailed
    case zipFailed

    var errorDescription: String? {
        switch self {
        case .emptyQuotes:
            return "No quotes available to export."
        case .encodingFailed:
            return "Failed to encode export content."
        case .writeFailed:
            return "Failed to write export file."
        case .zipFailed:
            return "Failed to package export files."
        }
    }
}

// MARK: - Helpers

enum ExportFileWriter {
    private static let exportDirectoryName = "BookQuotesExports"

    static func exportDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(exportDirectoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }

    static func saveText(_ text: String, filename: String) throws -> URL {
        guard let data = text.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }

        return try saveData(data, filename: filename)
    }

    static func saveData(_ data: Data, filename: String) throws -> URL {
        let directory = try exportDirectory()
        let sanitized = sanitizeFilename(filename)
        let url = directory.appendingPathComponent(sanitized)

        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw ExportError.writeFailed
        }

        return url
    }

    static func packageTextFiles(
        _ files: [(filename: String, content: String)],
        bundleName: String
    ) throws -> ExportResult {
        guard !files.isEmpty else {
            throw ExportError.emptyQuotes
        }

        if files.count == 1, let single = files.first {
            let url = try saveText(single.content, filename: single.filename)
            return .file(url, filename: single.filename)
        }

        let directory = try exportDirectory()
        let bundleDirectory = directory.appendingPathComponent(
            sanitizeFilename(bundleName),
            isDirectory: true
        )

        if !FileManager.default.fileExists(atPath: bundleDirectory.path) {
            try FileManager.default.createDirectory(
                at: bundleDirectory,
                withIntermediateDirectories: true
            )
        }

        for file in files {
            let url = bundleDirectory.appendingPathComponent(sanitizeFilename(file.filename))
            guard let data = file.content.data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            try data.write(to: url, options: [.atomic])
        }

        let zipURL = directory.appendingPathComponent("\(sanitizeFilename(bundleName)).zip")

        if #available(iOS 16.0, *) {
            do {
                try FileManager.default.zipItem(at: bundleDirectory, to: zipURL)
            } catch {
                throw ExportError.zipFailed
            }
            return .file(zipURL, filename: zipURL.lastPathComponent)
        }

        return .file(bundleDirectory, filename: bundleDirectory.lastPathComponent)
    }

    static func sanitizeFilename(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = value.components(separatedBy: invalidCharacters).joined(separator: "-")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension ExportOptions {
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
}
