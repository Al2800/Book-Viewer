import Foundation

// MARK: - Book Metadata

/// Temporary metadata extracted from book cover or ISBN lookup.
/// Used as an intermediate format before creating a Book model.
struct BookMetadata: Identifiable, Sendable {
    // MARK: - Identity

    let id: UUID

    // MARK: - Core Fields

    /// Book title
    var title: String

    /// Author names
    var authors: [String]

    /// Subtitle (if any)
    var subtitle: String?

    /// ISBN-10 or ISBN-13
    var isbn: String?

    // MARK: - Publication Info

    /// Publisher name
    var publisher: String?

    /// Year of publication
    var publishYear: Int?

    /// Edition (e.g., "First Edition", "Revised")
    var edition: String?

    // MARK: - Classification

    /// Genre or category
    var genre: String?

    /// Subject tags
    var tags: [String]

    // MARK: - Physical Details

    /// Number of pages
    var pageCount: Int?

    /// Language code (e.g., "en", "es")
    var language: String?

    // MARK: - Cover Image

    /// Cover image data (JPEG/PNG)
    var coverImageData: Data?

    /// URL to cover image (from ISBN lookup)
    var coverImageURL: URL?

    // MARK: - Extraction Info

    /// Source of this metadata
    var source: MetadataSource

    /// Confidence in the extraction (0.0-1.0)
    var confidence: Double?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        authors: [String],
        subtitle: String? = nil,
        isbn: String? = nil,
        publisher: String? = nil,
        publishYear: Int? = nil,
        edition: String? = nil,
        genre: String? = nil,
        tags: [String] = [],
        pageCount: Int? = nil,
        language: String? = nil,
        coverImageData: Data? = nil,
        coverImageURL: URL? = nil,
        source: MetadataSource = .manual,
        confidence: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.subtitle = subtitle
        self.isbn = isbn
        self.publisher = publisher
        self.publishYear = publishYear
        self.edition = edition
        self.genre = genre
        self.tags = tags
        self.pageCount = pageCount
        self.language = language
        self.coverImageData = coverImageData
        self.coverImageURL = coverImageURL
        self.source = source
        self.confidence = confidence
    }

    // MARK: - Computed Properties

    /// Primary author name (first in the list)
    var primaryAuthor: String {
        authors.first ?? "Unknown Author"
    }

    /// Combined author names for display
    var authorDisplay: String {
        switch authors.count {
        case 0:
            return "Unknown Author"
        case 1:
            return authors[0]
        case 2:
            return "\(authors[0]) & \(authors[1])"
        default:
            return "\(authors[0]) et al."
        }
    }

    /// Full title including subtitle
    var fullTitle: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title): \(subtitle)"
        }
        return title
    }

    /// Whether this metadata has enough info to create a book
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether cover image is available
    var hasCover: Bool {
        coverImageData != nil || coverImageURL != nil
    }

    // MARK: - Conversion

    /// Convert to a Book model
    func toBook() -> Book {
        let book = Book(title: title, author: authorDisplay)

        book.isbn = isbn
        book.publisher = publisher
        book.publishYear = publishYear
        book.genre = genre
        book.coverThumbnailData = coverImageData

        return book
    }
}

// MARK: - Metadata Source

extension BookMetadata {
    /// Source of the extracted metadata
    enum MetadataSource: String, Codable, Sendable {
        /// Manually entered by user
        case manual

        /// Extracted from cover photo via AI
        case coverPhoto

        /// Looked up via ISBN barcode
        case isbnLookup

        /// Imported from external source
        case imported

        var displayName: String {
            switch self {
            case .manual: return "Manual Entry"
            case .coverPhoto: return "Cover Photo"
            case .isbnLookup: return "ISBN Lookup"
            case .imported: return "Imported"
            }
        }
    }
}

// MARK: - Empty Metadata

extension BookMetadata {
    /// Empty metadata for manual entry
    static var empty: BookMetadata {
        BookMetadata(title: "", authors: [], source: .manual)
    }

    /// Create from ISBN lookup result
    static func fromISBNLookup(_ result: ISBNLookupResult) -> BookMetadata {
        switch result {
        case .googleBooks(let item):
            return BookMetadata(
                title: item.volumeInfo.title,
                authors: item.volumeInfo.authors ?? [],
                subtitle: item.volumeInfo.subtitle,
                publisher: item.volumeInfo.publisher,
                publishYear: extractYear(from: item.volumeInfo.publishedDate),
                genre: item.volumeInfo.categories?.first,
                pageCount: item.volumeInfo.pageCount,
                coverImageURL: URL(string: item.volumeInfo.imageLinks?.thumbnail ?? ""),
                source: .isbnLookup
            )

        case .openLibrary(let work, let edition):
            return BookMetadata(
                title: edition.title ?? work.title,
                authors: work.authorNames ?? [],
                publisher: edition.publishers?.first,
                publishYear: extractYear(from: edition.publishDate),
                pageCount: edition.numberOfPages,
                source: .isbnLookup
            )
        }
    }

    private static func extractYear(from dateString: String?) -> Int? {
        guard let dateString = dateString else { return nil }
        // Try to extract 4-digit year
        let yearPattern = /\d{4}/
        if let match = dateString.firstMatch(of: yearPattern) {
            return Int(match.output)
        }
        return nil
    }
}

// MARK: - Codable

extension BookMetadata: Codable {}
extension BookMetadata.MetadataSource: CaseIterable {}
