import Foundation

// MARK: - OpenLibrary API Response Models

/// OpenLibrary returns a dictionary keyed by the ISBN query
/// e.g., {"ISBN:0451526538": {...}}
typealias OpenLibraryBooksResponse = [String: OpenLibraryBookData]

/// Individual book data from OpenLibrary
struct OpenLibraryBookData: Codable {
    let url: String?
    let key: String?
    let title: String
    let subtitle: String?
    let authors: [OpenLibraryAuthor]?
    let publishers: [OpenLibraryPublisher]?
    let publishPlaces: [OpenLibraryPlace]?
    let publishDate: String?
    let subjects: [OpenLibrarySubject]?
    let notes: String?
    let numberOfPages: Int?
    let cover: OpenLibraryCover?
    let identifiers: OpenLibraryIdentifiers?
    let excerpts: [OpenLibraryExcerpt]?
    let weight: String?

    private enum CodingKeys: String, CodingKey {
        case url, key, title, subtitle, authors, publishers
        case publishPlaces = "publish_places"
        case publishDate = "publish_date"
        case subjects, notes
        case numberOfPages = "number_of_pages"
        case cover, identifiers, excerpts, weight
    }
}

/// Author information
struct OpenLibraryAuthor: Codable {
    let name: String
    let url: String?
}

/// Publisher information
struct OpenLibraryPublisher: Codable {
    let name: String
}

/// Publication place
struct OpenLibraryPlace: Codable {
    let name: String
}

/// Subject/category
struct OpenLibrarySubject: Codable {
    let name: String
    let url: String?
}

/// Cover image URLs
struct OpenLibraryCover: Codable {
    let small: String?
    let medium: String?
    let large: String?

    /// Best available cover URL
    var bestAvailable: String? {
        large ?? medium ?? small
    }
}

/// Various identifiers (ISBN, OCLC, etc.)
struct OpenLibraryIdentifiers: Codable {
    let isbn10: [String]?
    let isbn13: [String]?
    let oclc: [String]?
    let lccn: [String]?
    let openlibrary: [String]?
    let goodreads: [String]?
    let librarything: [String]?

    private enum CodingKeys: String, CodingKey {
        case isbn10 = "isbn_10"
        case isbn13 = "isbn_13"
        case oclc, lccn, openlibrary, goodreads, librarything
    }
}

/// Book excerpt
struct OpenLibraryExcerpt: Codable {
    let text: String
    let comment: String?
}

// MARK: - OpenLibrary Works API (alternative endpoint)

/// Response from OpenLibrary Works API
struct OpenLibraryWorksResponse: Codable {
    let title: String?
    let key: String?
    let authors: [OpenLibraryWorksAuthor]?
    let type: OpenLibraryType?
    let description: OpenLibraryDescription?
    let covers: [Int]?
    let subjects: [String]?
    let subjectPlaces: [String]?
    let subjectTimes: [String]?
    let subjectPeople: [String]?

    private enum CodingKeys: String, CodingKey {
        case title, key, authors, type, description, covers, subjects
        case subjectPlaces = "subject_places"
        case subjectTimes = "subject_times"
        case subjectPeople = "subject_people"
    }
}

struct OpenLibraryWorksAuthor: Codable {
    let author: OpenLibraryAuthorRef?
    let type: OpenLibraryType?
}

struct OpenLibraryAuthorRef: Codable {
    let key: String
}

struct OpenLibraryType: Codable {
    let key: String
}

/// Description can be a string or an object with value
enum OpenLibraryDescription: Codable {
    case string(String)
    case object(OpenLibraryDescriptionObject)

    var text: String? {
        switch self {
        case .string(let str):
            return str
        case .object(let obj):
            return obj.value
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let obj = try? container.decode(OpenLibraryDescriptionObject.self) {
            self = .object(obj)
        } else {
            throw DecodingError.typeMismatch(
                OpenLibraryDescription.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected string or object")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .object(let obj):
            try container.encode(obj)
        }
    }
}

struct OpenLibraryDescriptionObject: Codable {
    let type: String?
    let value: String
}

// MARK: - Conversion to BookMetadata

extension OpenLibraryBookData {
    /// Convert to our internal BookMetadata format
    func toBookMetadata() -> BookMetadata {
        // Parse published year from date string
        var publishedYear: Int?
        if let dateString = publishDate {
            // Try to extract 4-digit year
            let yearPattern = #"(\d{4})"#
            if let regex = try? NSRegularExpression(pattern: yearPattern),
               let match = regex.firstMatch(in: dateString, range: NSRange(dateString.startIndex..., in: dateString)),
               let yearRange = Range(match.range(at: 1), in: dateString) {
                publishedYear = Int(dateString[yearRange])
            }
        }

        return BookMetadata(
            title: title,
            subtitle: subtitle,
            authors: authors?.map(\.name) ?? [],
            publisher: publishers?.first?.name,
            publishedYear: publishedYear,
            publishedDate: publishDate,
            isbn10: identifiers?.isbn10?.first,
            isbn13: identifiers?.isbn13?.first,
            pageCount: numberOfPages,
            description: notes,
            categories: subjects?.map(\.name) ?? [],
            language: nil,
            thumbnailURL: cover?.small ?? cover?.medium,
            coverURL: cover?.bestAvailable,
            averageRating: nil,
            ratingsCount: nil,
            source: .openLibrary,
            openLibraryKey: key
        )
    }
}
