import Foundation
import SwiftData

// MARK: - QuoteCorrection

/// Tracks user corrections to extracted quotes.
/// Used for improving future extraction accuracy by analyzing correction patterns.
@Model
final class QuoteCorrection {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Original and Corrected Data

    /// The original extracted text before correction
    var originalText: String

    /// The corrected text after user edit
    var correctedText: String

    /// Type of correction made
    var correctionType: CorrectionType

    /// Additional context about the correction (optional)
    var correctionNote: String?

    // MARK: - Metadata

    /// When the correction was made
    var dateCreated: Date

    /// The extraction confidence of the original text (if available)
    var originalConfidence: Double?

    /// The marking type of the original quote (if changed)
    var originalMarkingType: String?

    /// The corrected marking type (if changed)
    var correctedMarkingType: String?

    /// Original page number (if changed)
    var originalPageNumber: Int?

    /// Corrected page number (if changed)
    var correctedPageNumber: Int?

    // MARK: - Relationships

    /// The quote that was corrected
    @Relationship(deleteRule: .nullify)
    var quote: Quote?

    /// The book the quote belongs to
    @Relationship(deleteRule: .nullify)
    var book: Book?

    // MARK: - Initialization

    init(
        quote: Quote? = nil,
        originalText: String,
        correctedText: String,
        correctionType: CorrectionType
    ) {
        self.id = UUID()
        self.quote = quote
        self.book = quote?.book
        self.originalText = originalText
        self.correctedText = correctedText
        self.correctionType = correctionType
        self.dateCreated = Date()
        self.originalConfidence = quote?.confidence
    }
}

// MARK: - CorrectionType

extension QuoteCorrection {
    /// Types of corrections users can make
    enum CorrectionType: String, Codable, CaseIterable {
        /// User modified the quote text
        case textEdit = "text_edit"

        /// User changed the page number
        case pageNumber = "page_number"

        /// User changed the marking type
        case markingType = "marking_type"

        /// User changed the margin note
        case marginNote = "margin_note"

        /// User deleted an incorrectly extracted quote
        case deletion = "deletion"

        /// User manually added a quote (extraction missed it)
        case addition = "addition"

        /// User merged two quotes that were incorrectly split
        case merge = "merge"

        /// User split a quote that was incorrectly merged
        case split = "split"

        var displayName: String {
            switch self {
            case .textEdit: return "Text Edit"
            case .pageNumber: return "Page Number"
            case .markingType: return "Marking Type"
            case .marginNote: return "Margin Note"
            case .deletion: return "Deletion"
            case .addition: return "Manual Addition"
            case .merge: return "Merged Quotes"
            case .split: return "Split Quote"
            }
        }

        var systemImage: String {
            switch self {
            case .textEdit: return "pencil"
            case .pageNumber: return "number"
            case .markingType: return "pencil.line"
            case .marginNote: return "note.text"
            case .deletion: return "trash"
            case .addition: return "plus.circle"
            case .merge: return "arrow.triangle.merge"
            case .split: return "arrow.triangle.branch"
            }
        }
    }
}

// MARK: - Quote Extension

extension Quote {
    /// Record a text correction for this quote
    func recordTextCorrection(
        original: String,
        corrected: String,
        context: ModelContext
    ) {
        let correction = QuoteCorrection(
            quote: self,
            originalText: original,
            correctedText: corrected,
            correctionType: .textEdit
        )
        context.insert(correction)
        self.dateModified = Date()
    }

    /// Record a page number correction for this quote
    func recordPageCorrection(
        originalPage: Int?,
        correctedPage: Int?,
        context: ModelContext
    ) {
        let correction = QuoteCorrection(
            quote: self,
            originalText: "",
            correctedText: "",
            correctionType: .pageNumber
        )
        correction.originalPageNumber = originalPage
        correction.correctedPageNumber = correctedPage
        context.insert(correction)
        self.dateModified = Date()
    }

    /// Record a marking type correction for this quote
    func recordMarkingTypeCorrection(
        originalType: String,
        correctedType: String,
        context: ModelContext
    ) {
        let correction = QuoteCorrection(
            quote: self,
            originalText: "",
            correctedText: "",
            correctionType: .markingType
        )
        correction.originalMarkingType = originalType
        correction.correctedMarkingType = correctedType
        context.insert(correction)
        self.dateModified = Date()
    }

    /// Record a margin note correction for this quote
    func recordMarginNoteCorrection(
        originalNote: String,
        correctedNote: String,
        context: ModelContext
    ) {
        let correction = QuoteCorrection(
            quote: self,
            originalText: originalNote,
            correctedText: correctedNote,
            correctionType: .marginNote
        )
        context.insert(correction)
        self.dateModified = Date()
    }
}

// MARK: - Statistics

extension QuoteCorrection {
    /// Descriptor for all corrections sorted by date
    static var all: FetchDescriptor<QuoteCorrection> {
        FetchDescriptor<QuoteCorrection>(
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
    }

    /// Descriptor for corrections of a specific type
    static func ofType(_ type: CorrectionType) -> FetchDescriptor<QuoteCorrection> {
        FetchDescriptor<QuoteCorrection>(
            predicate: #Predicate { $0.correctionType == type },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
    }

    /// Descriptor for corrections for a specific book
    static func forBook(_ book: Book) -> FetchDescriptor<QuoteCorrection> {
        let bookId = book.id
        return FetchDescriptor<QuoteCorrection>(
            predicate: #Predicate { $0.book?.id == bookId },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
    }
}

// MARK: - Analysis Helpers

extension Array where Element == QuoteCorrection {
    /// Count corrections by type
    var countsByType: [QuoteCorrection.CorrectionType: Int] {
        var counts: [QuoteCorrection.CorrectionType: Int] = [:]
        for correction in self {
            counts[correction.correctionType, default: 0] += 1
        }
        return counts
    }

    /// Calculate average confidence of corrected quotes
    var averageOriginalConfidence: Double? {
        let confidences = compactMap(\.originalConfidence)
        guard !confidences.isEmpty else { return nil }
        return confidences.reduce(0, +) / Double(confidences.count)
    }

    /// Most common correction type
    var mostCommonType: QuoteCorrection.CorrectionType? {
        countsByType.max(by: { $0.value < $1.value })?.key
    }
}
