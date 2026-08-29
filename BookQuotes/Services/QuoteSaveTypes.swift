import CoreGraphics
import Foundation

// MARK: - Extracted Quote

/// Represents quote data extracted before persistence.
struct ExtractedQuote {
    let text: String
    let markingType: MarkingType
    let confidence: Double?
    let pageNumber: Int?
    let chapter: String?
    let marginNote: String?
    let customMarkingDefinition: MarkingDefinition?
    let boundingBox: CGRect?
    let suggestedTags: [String]?

    init(
        text: String,
        markingType: MarkingType = .underline,
        confidence: Double? = nil,
        pageNumber: Int? = nil,
        chapter: String? = nil,
        marginNote: String? = nil,
        customMarkingDefinition: MarkingDefinition? = nil,
        boundingBox: CGRect? = nil,
        suggestedTags: [String]? = nil
    ) {
        self.text = text
        self.markingType = markingType
        self.confidence = confidence
        self.pageNumber = pageNumber
        self.chapter = chapter
        self.marginNote = marginNote
        self.customMarkingDefinition = customMarkingDefinition
        self.boundingBox = boundingBox
        self.suggestedTags = suggestedTags
    }
}

// MARK: - Batch Save Result

/// Result of a batch save operation.
struct BatchSaveResult {
    let savedQuotes: [Quote]
    let failures: [SaveFailure]
    let book: Book

    var isFullSuccess: Bool {
        failures.isEmpty
    }

    var isPartialSuccess: Bool {
        !savedQuotes.isEmpty && !failures.isEmpty
    }

    var isFullFailure: Bool {
        savedQuotes.isEmpty && !failures.isEmpty
    }

    var totalAttempted: Int {
        savedQuotes.count + failures.count
    }

    var successRate: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(savedQuotes.count) / Double(totalAttempted)
    }

    var summary: String {
        if isFullSuccess {
            return "Saved \(savedQuotes.count) quote\(savedQuotes.count == 1 ? "" : "s")"
        } else if isFullFailure {
            return "Failed to save \(failures.count) quote\(failures.count == 1 ? "" : "s")"
        } else {
            return "Saved \(savedQuotes.count) of \(totalAttempted) quotes"
        }
    }
}

// MARK: - Save Failure

/// Details about a failed quote save.
struct SaveFailure {
    let index: Int
    let extractedQuote: ExtractedQuote
    let error: Error

    var errorMessage: String {
        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }
        return error.localizedDescription
    }
}

// MARK: - Save Errors

enum QuoteSaveError: LocalizedError {
    case bookNotFound
    case invalidQuoteData(String)
    case persistenceFailed(Error)
    case duplicateQuote

    var errorDescription: String? {
        switch self {
        case .bookNotFound:
            return "The selected book could not be found"
        case .invalidQuoteData(let reason):
            return "Invalid quote data: \(reason)"
        case .persistenceFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .duplicateQuote:
            return "This quote already exists in your library"
        }
    }
}
