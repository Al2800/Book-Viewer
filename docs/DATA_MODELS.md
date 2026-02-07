# Data Models Specification

## Overview

This document provides detailed specifications for all data models used in BookQuotes. Models are implemented using SwiftData for persistence with iCloud sync capability.

---

## Core Models

### Book

The primary container for organizing quotes from a single book.

```swift
import SwiftData
import Foundation

@Model
final class Book {
    // MARK: - Identity

    /// Unique identifier (auto-generated UUID)
    @Attribute(.unique) var id: UUID

    // MARK: - Metadata (from cover recognition)

    /// The book's title (required)
    var title: String

    /// Author name(s), may include multiple authors
    var author: String

    /// Book subtitle if present
    var subtitle: String?

    /// Publisher name
    var publisher: String?

    /// ISBN-10 or ISBN-13 if visible on cover
    var isbn: String?

    /// Total page count if known
    var pageCount: Int?

    // MARK: - Cover Image

    /// Cover image stored as JPEG data (thumbnail, max 400px wide)
    var coverThumbnailData: Data?

    /// Full-size cover image stored as JPEG data (max 1200px wide)
    var coverFullData: Data?

    // MARK: - Reading Status

    /// Current reading status
    var status: ReadingStatus

    // MARK: - Timestamps

    /// When the book was added to the library
    var dateAdded: Date

    /// When the user started reading (nil if not started)
    var dateStarted: Date?

    /// When the user finished reading (nil if not finished)
    var dateFinished: Date?

    /// Last time any data was modified
    var dateModified: Date

    // MARK: - User Notes

    /// Optional personal notes about the book
    var notes: String?

    /// User's rating (1-5 stars, nil if not rated)
    var rating: Int?

    // MARK: - Relationships

    /// All quotes captured from this book (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \Quote.book)
    var quotes: [Quote]

    // MARK: - Computed Properties

    /// Number of quotes captured from this book
    var quoteCount: Int { quotes.count }

    /// Whether the book has any quotes
    var hasQuotes: Bool { !quotes.isEmpty }

    // MARK: - Initialization

    init(
        title: String,
        author: String,
        subtitle: String? = nil,
        publisher: String? = nil,
        isbn: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.subtitle = subtitle
        self.publisher = publisher
        self.isbn = isbn
        self.status = .wantToRead
        self.dateAdded = Date()
        self.dateModified = Date()
        self.quotes = []
    }
}

// MARK: - Reading Status

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead = "want_to_read"
    case currentlyReading = "currently_reading"
    case finished = "finished"
    case abandoned = "abandoned"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wantToRead: return "Want to Read"
        case .currentlyReading: return "Currently Reading"
        case .finished: return "Finished"
        case .abandoned: return "Abandoned"
        }
    }

    var systemImage: String {
        switch self {
        case .wantToRead: return "bookmark"
        case .currentlyReading: return "book"
        case .finished: return "checkmark.circle"
        case .abandoned: return "xmark.circle"
        }
    }
}
```

### Quote

An individual quote or passage captured from a book.

```swift
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

    // MARK: - Computed Properties

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

    init(text: String, book: Book, markingType: MarkingType = .underline) {
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

// MARK: - Marking Type

enum MarkingType: String, Codable, CaseIterable, Identifiable {
    case underline = "underline"
    case doubleUnderline = "double_underline"
    case marginLine = "margin_line"
    case highlight = "highlight"
    case marginNote = "margin_note"
    case bracket = "bracket"
    case mixed = "mixed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .underline: return "Underline"
        case .doubleUnderline: return "Double Underline"
        case .marginLine: return "Margin Line"
        case .highlight: return "Highlight"
        case .marginNote: return "Margin Note"
        case .bracket: return "Bracket"
        case .mixed: return "Mixed Markings"
        }
    }

    var description: String {
        switch self {
        case .underline: return "Single line under text"
        case .doubleUnderline: return "Double line under text"
        case .marginLine: return "Vertical line in margin"
        case .highlight: return "Highlighted/colored text"
        case .marginNote: return "Handwritten note in margin"
        case .bracket: return "Bracketed passage"
        case .mixed: return "Multiple marking styles"
        }
    }

    var systemImage: String {
        switch self {
        case .underline: return "underline"
        case .doubleUnderline: return "underline.badge.2"
        case .marginLine: return "sidebar.leading"
        case .highlight: return "highlighter"
        case .marginNote: return "note.text"
        case .bracket: return "brackets"
        case .mixed: return "checklist"
        }
    }
}
```

### Collection

User-created groupings of quotes.

```swift
@Model
final class Collection {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Properties

    /// Collection name
    var name: String

    /// SF Symbol icon name
    var icon: String

    /// Color identifier (from predefined palette)
    var colorName: String

    /// Optional description
    var collectionDescription: String?

    // MARK: - Timestamps

    var dateCreated: Date
    var dateModified: Date

    // MARK: - Sorting

    /// Display order (lower = first)
    var sortOrder: Int

    // MARK: - Relationships

    var quotes: [Quote]

    // MARK: - Computed

    var quoteCount: Int { quotes.count }

    // MARK: - Initialization

    init(name: String, icon: String = "folder", colorName: String = "blue") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.dateCreated = Date()
        self.dateModified = Date()
        self.sortOrder = 0
        self.quotes = []
    }
}

// MARK: - Collection Colors

enum CollectionColor: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}
```

### Tag

Lightweight labels for cross-cutting categorization.

```swift
@Model
final class Tag {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    /// Tag name (unique, case-insensitive)
    @Attribute(.unique) var name: String

    // MARK: - Timestamps

    var dateCreated: Date

    // MARK: - Relationships

    var quotes: [Quote]

    // MARK: - Computed

    var quoteCount: Int { quotes.count }

    // MARK: - Initialization

    init(name: String) {
        self.id = UUID()
        self.name = name.lowercased().trimmingCharacters(in: .whitespaces)
        self.dateCreated = Date()
        self.quotes = []
    }
}
```

---

## API Response Models

These models are used for parsing Gemini API responses before converting to persistent models.

### BookMetadataResponse

```swift
/// Response from Gemini book cover analysis
struct BookMetadataResponse: Codable {
    let title: String
    let author: String
    let subtitle: String?
    let publisher: String?
    let isbn: String?
    let pageCount: Int?
    let confidence: Double?

    /// Convert to Book model
    func toBook() -> Book {
        Book(
            title: title,
            author: author,
            subtitle: subtitle,
            publisher: publisher,
            isbn: isbn
        )
    }
}
```

### ExtractedQuoteResponse

```swift
/// Response from Gemini quote extraction
struct ExtractedQuoteResponse: Codable {
    let text: String
    let pageNumber: Int?
    let marginNote: String?
    let markingType: String
    let confidence: Double?

    var markingTypeEnum: MarkingType {
        MarkingType(rawValue: markingType) ?? .underline
    }

    /// Convert to Quote model (requires associated book)
    func toQuote(book: Book) -> Quote {
        let quote = Quote(text: text, book: book, markingType: markingTypeEnum)
        quote.pageNumber = pageNumber
        quote.marginNote = marginNote
        return quote
    }
}

/// Container for multiple extracted quotes
struct QuoteExtractionResponse: Codable {
    let quotes: [ExtractedQuoteResponse]
    let pageNumber: Int? // Global page number if detected
    let processingNotes: String? // Any AI notes about the extraction
}
```

---

## Query Descriptors

Pre-defined query descriptors for common data access patterns.

```swift
extension Book {
    /// All books sorted by date added (newest first)
    static var recentlyAdded: FetchDescriptor<Book> {
        var descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return descriptor
    }

    /// Books currently being read
    static var currentlyReading: FetchDescriptor<Book> {
        var descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.status == .currentlyReading },
            sortBy: [SortDescriptor(\.dateStarted, order: .reverse)]
        )
        return descriptor
    }

    /// Books with quotes, sorted by quote count
    static var withQuotes: FetchDescriptor<Book> {
        var descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { !$0.quotes.isEmpty },
            sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
        )
        return descriptor
    }

    /// Search books by title or author
    static func search(_ query: String) -> FetchDescriptor<Book> {
        let lowercased = query.lowercased()
        return FetchDescriptor<Book>(
            predicate: #Predicate {
                $0.title.localizedStandardContains(lowercased) ||
                $0.author.localizedStandardContains(lowercased)
            },
            sortBy: [SortDescriptor(\.title)]
        )
    }
}

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

    /// Random quote (for widget/discovery)
    static func random(limit: Int = 1) -> FetchDescriptor<Quote> {
        var descriptor = FetchDescriptor<Quote>()
        descriptor.fetchLimit = limit
        // Note: True randomness requires additional logic
        return descriptor
    }
}
```

---

## Model Container Configuration

```swift
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([
            Book.self,
            Quote.self,
            Collection.self,
            Tag.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Preview container with sample data
    static var preview: PersistenceController {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext

        // Add sample data
        let sampleBook = Book(
            title: "Meditations",
            author: "Marcus Aurelius"
        )
        sampleBook.status = .currentlyReading
        context.insert(sampleBook)

        let sampleQuote = Quote(
            text: "You have power over your mind - not outside events. Realize this, and you will find strength.",
            book: sampleBook
        )
        sampleQuote.pageNumber = 42
        context.insert(sampleQuote)

        return controller
    }
}
```

---

## Migration Strategy

For future schema changes:

```swift
enum BookQuotesSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Book.self, Quote.self, Collection.self, Tag.self]
    }
}

enum BookQuotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BookQuotesSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
```

---

## Validation Rules

```swift
extension Book {
    /// Validate book data before saving
    func validate() throws {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyTitle
        }
        guard !author.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyAuthor
        }
        if let rating = rating, !(1...5).contains(rating) {
            throw ValidationError.invalidRating
        }
    }
}

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

enum ValidationError: LocalizedError {
    case emptyTitle
    case emptyAuthor
    case emptyQuote
    case quoteTooShort
    case invalidRating

    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Book title cannot be empty"
        case .emptyAuthor: return "Author name cannot be empty"
        case .emptyQuote: return "Quote text cannot be empty"
        case .quoteTooShort: return "Quote must be at least 10 characters"
        case .invalidRating: return "Rating must be between 1 and 5"
        }
    }
}
```

---

## Index Recommendations

For optimal query performance:

1. **Book.title** - For search and alphabetical sorting
2. **Book.author** - For search and filtering by author
3. **Book.status** - For filtering by reading status
4. **Book.dateAdded** - For recent books list
5. **Quote.captureDate** - For recent quotes list
6. **Quote.isFavorite** - For favorites filter
7. **Tag.name** - For tag lookup and uniqueness
8. **Collection.sortOrder** - For ordered collection display

SwiftData handles most indexing automatically, but complex queries may benefit from explicit index hints in future versions.

---

## Schema Changes and Migrations

BookQuotes defines an explicit SwiftData schema at app launch (see `BookQuotes/App/BookQuotesApp.swift`). When you add or change `@Model` types, you must update that schema list so the model is actually persisted in production (tests use a separate in-memory container).

### Practical Rules

1. Additive changes (new optional properties, new models) are usually safe, but should still be validated on an existing store.
2. Destructive changes (renames, type changes, removing properties, relationship changes) should be treated as requiring an explicit migration plan.
3. CloudKit-backed stores can surface migration problems later than local-only stores. Always test upgrade flows.

### Manual Upgrade Test (Recommended)

1. Install an older build on a simulator or device.
2. Create representative data: books, quotes, tags, collections, offline queue items.
3. Install the new build over the old one.
4. Verify:
   - App launches without a storage initialization error.
   - Existing objects load correctly and basic CRUD still works.
   - Console logs do not show SwiftData/CoreData migration failures.

### Automation Note

Our unit/integration tests use in-memory SwiftData containers, which validate model logic and predicates but do not validate disk-store migrations. Treat model/schema changes as needing a manual upgrade check unless we add a versioned `SchemaMigrationPlan`.
