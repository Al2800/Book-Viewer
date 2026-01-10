import Foundation
import SwiftData

// MARK: - Quote Model

@Model
final class Quote {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Content

    /// The extracted quote text (required)
    var text: String

    /// Page number where quote appears (optional)
    var pageNumber: Int?

    /// Chapter name or number if identifiable
    var chapter: String?

    /// Transcribed handwritten margin note (if any)
    var marginNote: String?

    // MARK: - Capture Metadata

    /// Type of marking used to highlight this passage
    var markingType: MarkingType

    /// When the quote was captured
    var captureDate: Date

    /// Last modification date
    var dateModified: Date

    // MARK: - Source Image

    /// Original captured image (JPEG, max 2048px)
    /// Stored for reference and potential re-processing
    var sourceImageData: Data?

    // MARK: - AI Confidence

    /// AI extraction confidence (0.0 to 1.0)
    var confidence: Double?

    // MARK: - User Additions

    /// User's personal reflection or note about the quote
    var personalNote: String?

    /// Whether this quote is marked as favorite
    var isFavorite: Bool

    // MARK: - Relationships

    /// The book this quote belongs to
    var book: Book?

    /// Tags applied to this quote
    @Relationship(inverse: \Tag.quotes)
    var tags: [Tag]

    /// Collections containing this quote
    @Relationship(inverse: \Collection.quotes)
    var collections: [Collection]

    /// Custom marking definition (user-defined vocabulary)
    var customMarkingDefinition: MarkingDefinition?

    // MARK: - Computed Properties

    /// Display name for the marking (prefers custom definition over legacy enum)
    var markingDisplayName: String {
        customMarkingDefinition?.name ?? markingType.displayName
    }

    /// Full attribution string
    var attribution: String {
        guard let book = book else { return "" }
        var parts = [book.title, "by \(book.author)"]
        if let page = pageNumber {
            parts.append("p. \(page)")
        }
        return parts.joined(separator: " - ")
    }

    /// Short attribution (title only)
    var shortAttribution: String {
        book?.title ?? "Unknown"
    }

    // MARK: - Initialization

    init(text: String, book: Book? = nil, markingType: MarkingType = .underline) {
        self.id = UUID()
        self.text = text
        self.markingType = markingType
        self.captureDate = Date()
        self.dateModified = Date()
        self.isFavorite = false
        self.book = book
        self.tags = []
        self.collections = []
    }
}

// MARK: - Validation

extension Quote {
    /// Validate quote data before saving
    func validate() throws {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyQuote
        }
        guard text.count >= 10 else {
            throw ValidationError.quoteTooShort
        }
    }
}

// MARK: - Query Descriptors

extension Quote {
    /// All quotes sorted by capture date (newest first)
    static var recent: FetchDescriptor<Quote> {
        FetchDescriptor<Quote>(
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
    }

    /// Favorite quotes only
    static var favorites: FetchDescriptor<Quote> {
        FetchDescriptor<Quote>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
    }

    /// Full-text search across quotes
    static func search(_ query: String) -> FetchDescriptor<Quote> {
        FetchDescriptor<Quote>(
            predicate: #Predicate {
                $0.text.localizedStandardContains(query) ||
                ($0.marginNote?.localizedStandardContains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
    }
}
