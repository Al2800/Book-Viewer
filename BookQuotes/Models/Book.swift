import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID

    var title: String
    var author: String
    var subtitle: String?
    var publisher: String?
    var isbn: String?
    var pageCount: Int?

    var coverThumbnailData: Data?
    var coverFullData: Data?

    var status: ReadingStatus

    var dateAdded: Date
    var dateStarted: Date?
    var dateFinished: Date?
    var dateModified: Date

    var notes: String?
    var rating: Int?

    @Relationship(deleteRule: .cascade, inverse: \Quote.book)
    var quotes: [Quote]

    var quoteCount: Int { quotes.count }
    var hasQuotes: Bool { !quotes.isEmpty }

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

// MARK: - Validation

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

// MARK: - Query Descriptors

extension Book {
    /// All books sorted by date added (newest first)
    static var recentlyAdded: FetchDescriptor<Book> {
        FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
    }

    /// Books currently being read
    static var currentlyReading: FetchDescriptor<Book> {
        FetchDescriptor<Book>(
            predicate: #Predicate { $0.status == .currentlyReading },
            sortBy: [SortDescriptor(\.dateStarted, order: .reverse)]
        )
    }

    /// Books with quotes, sorted by date modified
    static var withQuotes: FetchDescriptor<Book> {
        FetchDescriptor<Book>(
            predicate: #Predicate { !$0.quotes.isEmpty },
            sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
        )
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

// MARK: - Reading Status

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead = "want_to_read"
    case currentlyReading = "currently_reading"
    case finished = "finished"
    case abandoned = "abandoned"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wantToRead:
            return "Want to Read"
        case .currentlyReading:
            return "Currently Reading"
        case .finished:
            return "Finished"
        case .abandoned:
            return "Abandoned"
        }
    }

    var systemImage: String {
        switch self {
        case .wantToRead:
            return "bookmark"
        case .currentlyReading:
            return "book"
        case .finished:
            return "checkmark.circle"
        case .abandoned:
            return "xmark.circle"
        }
    }
}
