import Foundation

// MARK: - Google Books API Response Models

/// Root response from Google Books API volumes endpoint
struct GoogleBooksResponse: Codable {
    let kind: String?
    let totalItems: Int
    let items: [GoogleBooksItem]?
}

/// Individual volume item from Google Books
struct GoogleBooksItem: Codable {
    let kind: String?
    let id: String
    let etag: String?
    let selfLink: String?
    let volumeInfo: GoogleBooksVolumeInfo
    let saleInfo: GoogleBooksSaleInfo?
}

/// Volume information containing book metadata
struct GoogleBooksVolumeInfo: Codable {
    let title: String
    let subtitle: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [GoogleBooksIdentifier]?
    let readingModes: GoogleBooksReadingModes?
    let pageCount: Int?
    let printType: String?
    let categories: [String]?
    let averageRating: Double?
    let ratingsCount: Int?
    let maturityRating: String?
    let allowAnonLogging: Bool?
    let contentVersion: String?
    let panelizationSummary: GoogleBooksPanelization?
    let imageLinks: GoogleBooksImageLinks?
    let language: String?
    let previewLink: String?
    let infoLink: String?
    let canonicalVolumeLink: String?
}

/// ISBN and other identifiers
struct GoogleBooksIdentifier: Codable {
    let type: String // "ISBN_10", "ISBN_13", "OTHER"
    let identifier: String
}

/// Reading mode availability
struct GoogleBooksReadingModes: Codable {
    let text: Bool?
    let image: Bool?
}

/// Panelization info for ebooks
struct GoogleBooksPanelization: Codable {
    let containsEpubBubbles: Bool?
    let containsImageBubbles: Bool?
}

/// Cover image links at various resolutions
struct GoogleBooksImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    let extraLarge: String?

    /// Best available image URL (highest resolution)
    var bestAvailable: String? {
        extraLarge ?? large ?? medium ?? small ?? thumbnail ?? smallThumbnail
    }

    /// Thumbnail URL suitable for lists
    var thumbnailURL: String? {
        thumbnail ?? smallThumbnail
    }
}

/// Sale information
struct GoogleBooksSaleInfo: Codable {
    let country: String?
    let saleability: String?
    let isEbook: Bool?
}

// MARK: - Conversion to BookMetadata

extension GoogleBooksResponse {
    /// Convert the first matching item to BookMetadata
    func toBookMetadata() -> BookMetadata? {
        guard let item = items?.first else { return nil }
        return item.toBookMetadata()
    }
}

extension GoogleBooksItem {
    /// Convert to our internal BookMetadata format
    func toBookMetadata() -> BookMetadata {
        let info = volumeInfo

        // Extract ISBNs
        var isbn10: String?
        var isbn13: String?
        for identifier in info.industryIdentifiers ?? [] {
            switch identifier.type {
            case "ISBN_10":
                isbn10 = identifier.identifier
            case "ISBN_13":
                isbn13 = identifier.identifier
            default:
                break
            }
        }

        // Parse published date (can be "YYYY", "YYYY-MM", or "YYYY-MM-DD")
        var publishedYear: Int?
        if let dateString = info.publishedDate {
            let yearString = String(dateString.prefix(4))
            publishedYear = Int(yearString)
        }

        return BookMetadata(
            title: info.title,
            subtitle: info.subtitle,
            authors: info.authors ?? [],
            publisher: info.publisher,
            publishedYear: publishedYear,
            publishedDate: info.publishedDate,
            isbn10: isbn10,
            isbn13: isbn13,
            pageCount: info.pageCount,
            description: info.description,
            categories: info.categories ?? [],
            language: info.language,
            thumbnailURL: info.imageLinks?.thumbnailURL,
            coverURL: info.imageLinks?.bestAvailable,
            averageRating: info.averageRating,
            ratingsCount: info.ratingsCount,
            source: .googleBooks,
            googleBooksId: id
        )
    }
}
