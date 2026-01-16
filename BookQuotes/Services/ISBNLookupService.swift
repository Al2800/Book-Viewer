import Foundation

// MARK: - BookMetadata

/// Unified book metadata from various lookup sources.
/// Used to populate Book model after successful ISBN lookup.
struct BookMetadata: Sendable, Identifiable {
    let id: UUID
    // MARK: - Core Information

    let title: String
    let subtitle: String?
    let authors: [String]
    let publisher: String?
    let publishedYear: Int?
    let publishedDate: String?

    // MARK: - Identifiers

    let isbn10: String?
    let isbn13: String?

    // MARK: - Details

    let pageCount: Int?
    let description: String?
    let categories: [String]
    let language: String?

    // MARK: - Images

    let thumbnailURL: String?
    let coverURL: String?
    var coverImageData: Data?

    // MARK: - Ratings

    let averageRating: Double?
    let ratingsCount: Int?

    // MARK: - Source Tracking

    let source: MetadataSource
    let googleBooksId: String?
    let openLibraryKey: String?

    // MARK: - Computed Properties

    /// Primary author (first in list)
    var primaryAuthor: String? {
        authors.first
    }

    /// Authors formatted as comma-separated string
    var authorsFormatted: String {
        authors.joined(separator: ", ")
    }

    /// Best available ISBN (prefer ISBN-13)
    var isbn: String? {
        bestISBN
    }

    /// Best available ISBN (prefer ISBN-13)
    var bestISBN: String? {
        isbn13 ?? isbn10
    }

    /// Year published (matches app metadata naming)
    var publishYear: Int? {
        publishedYear
    }

    /// Primary genre (first category if available)
    var genre: String? {
        categories.first
    }

    /// URL to the cover image if available
    var coverImageURL: URL? {
        if let coverURL {
            return URL(string: coverURL)
        }
        if let thumbnailURL {
            return URL(string: thumbnailURL)
        }
        return nil
    }

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        authors: [String] = [],
        publisher: String? = nil,
        publishedYear: Int? = nil,
        publishedDate: String? = nil,
        isbn10: String? = nil,
        isbn13: String? = nil,
        pageCount: Int? = nil,
        description: String? = nil,
        categories: [String] = [],
        language: String? = nil,
        thumbnailURL: String? = nil,
        coverURL: String? = nil,
        coverImageData: Data? = nil,
        averageRating: Double? = nil,
        ratingsCount: Int? = nil,
        source: MetadataSource = .unknown,
        googleBooksId: String? = nil,
        openLibraryKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.authors = authors
        self.publisher = publisher
        self.publishedYear = publishedYear
        self.publishedDate = publishedDate
        self.isbn10 = isbn10
        self.isbn13 = isbn13
        self.pageCount = pageCount
        self.description = description
        self.categories = categories
        self.language = language
        self.thumbnailURL = thumbnailURL
        self.coverURL = coverURL
        self.coverImageData = coverImageData
        self.averageRating = averageRating
        self.ratingsCount = ratingsCount
        self.source = source
        self.googleBooksId = googleBooksId
        self.openLibraryKey = openLibraryKey
    }
}

/// Source of the book metadata
enum MetadataSource: String, Sendable {
    case googleBooks
    case openLibrary
    case manual
    case unknown
}

// MARK: - ISBNLookupService

/// Actor for looking up book metadata by ISBN.
/// Uses Google Books as primary source with OpenLibrary fallback.
actor ISBNLookupService {
    // MARK: - Configuration

    private let session: URLSession
    private let googleBooksBaseURL: URL
    private let openLibraryBaseURL: URL

    /// Cache for recent lookups to avoid repeated API calls
    private var cache: [String: CachedMetadata] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    private static func makeBaseURL(host: String, path: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        return components.url ?? URL(fileURLWithPath: "/")
    }

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session
        self.googleBooksBaseURL = ISBNLookupService.makeBaseURL(
            host: "www.googleapis.com",
            path: "/books/v1/volumes"
        )
        self.openLibraryBaseURL = ISBNLookupService.makeBaseURL(
            host: "openlibrary.org",
            path: "/api/books"
        )
    }

    // MARK: - Public API

    /// Look up book metadata by ISBN.
    /// Tries Google Books first, falls back to OpenLibrary if not found.
    /// - Parameter isbn: ISBN-10 or ISBN-13 (hyphens optional)
    /// - Returns: Book metadata if found
    /// - Throws: LookupError if lookup fails
    func lookup(isbn: String) async throws -> BookMetadata {
        let normalizedISBN = normalizeISBN(isbn)

        // Check cache first
        if let cached = cache[normalizedISBN], !cached.isExpired {
            return cached.metadata
        }

        // Try Google Books first (more comprehensive)
        if let metadata = try? await lookupGoogleBooks(isbn: normalizedISBN) {
            cacheMetadata(metadata, forISBN: normalizedISBN)
            return metadata
        }

        // Fallback to OpenLibrary
        if let metadata = try? await lookupOpenLibrary(isbn: normalizedISBN) {
            cacheMetadata(metadata, forISBN: normalizedISBN)
            return metadata
        }

        throw LookupError.notFound(isbn: normalizedISBN)
    }

    /// Look up using Google Books only
    func lookupGoogleBooks(isbn: String) async throws -> BookMetadata {
        let normalizedISBN = normalizeISBN(isbn)

        guard var components = URLComponents(url: googleBooksBaseURL, resolvingAgainstBaseURL: false) else {
            throw LookupError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: "isbn:\(normalizedISBN)")
        ]
        guard let url = components.url else {
            throw LookupError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LookupError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 429:
            throw LookupError.rateLimited
        case 400..<500:
            throw LookupError.clientError(httpResponse.statusCode)
        case 500..<600:
            throw LookupError.serverError(httpResponse.statusCode)
        default:
            throw LookupError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let booksResponse = try decoder.decode(GoogleBooksResponse.self, from: data)

        guard let metadata = booksResponse.toBookMetadata() else {
            throw LookupError.notFound(isbn: normalizedISBN)
        }

        return metadata
    }

    /// Look up using OpenLibrary only
    func lookupOpenLibrary(isbn: String) async throws -> BookMetadata {
        let normalizedISBN = normalizeISBN(isbn)

        guard var components = URLComponents(url: openLibraryBaseURL, resolvingAgainstBaseURL: false) else {
            throw LookupError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "bibkeys", value: "ISBN:\(normalizedISBN)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jscmd", value: "data")
        ]
        guard let url = components.url else {
            throw LookupError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LookupError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 429:
            throw LookupError.rateLimited
        case 400..<500:
            throw LookupError.clientError(httpResponse.statusCode)
        case 500..<600:
            throw LookupError.serverError(httpResponse.statusCode)
        default:
            throw LookupError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let booksResponse = try decoder.decode(OpenLibraryBooksResponse.self, from: data)

        // OpenLibrary returns a dict keyed by "ISBN:1234567890"
        let key = "ISBN:\(normalizedISBN)"
        guard let bookData = booksResponse[key] else {
            throw LookupError.notFound(isbn: normalizedISBN)
        }

        return bookData.toBookMetadata()
    }

    // MARK: - Cover Image Fetching

    /// Fetch cover image data from URL
    /// - Parameter url: Cover image URL
    /// - Returns: Image data
    func fetchCoverImage(from urlString: String) async throws -> Data {
        // Replace http with https for Google Books URLs
        var secureURL = urlString
        if secureURL.hasPrefix("http://") {
            secureURL = secureURL.replacingOccurrences(of: "http://", with: "https://")
        }

        guard let url = URL(string: secureURL) else {
            throw LookupError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LookupError.imageLoadFailed
        }

        return data
    }

    // MARK: - Cache Management

    /// Clear the metadata cache
    func clearCache() {
        cache.removeAll()
    }

    /// Remove expired entries from cache
    func pruneCache() {
        cache = cache.filter { !$0.value.isExpired }
    }

    // MARK: - Private Helpers

    private func normalizeISBN(_ isbn: String) -> String {
        isbn
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func cacheMetadata(_ metadata: BookMetadata, forISBN isbn: String) {
        cache[isbn] = CachedMetadata(metadata: metadata, cachedAt: Date())

        // Also cache under alternate ISBN if available
        if let isbn10 = metadata.isbn10, isbn10 != isbn {
            cache[isbn10] = CachedMetadata(metadata: metadata, cachedAt: Date())
        }
        if let isbn13 = metadata.isbn13, isbn13 != isbn {
            cache[isbn13] = CachedMetadata(metadata: metadata, cachedAt: Date())
        }
    }
}

// MARK: - Cache Entry

extension ISBNLookupService {
    private struct CachedMetadata {
        let metadata: BookMetadata
        let cachedAt: Date

        var isExpired: Bool {
            Date().timeIntervalSince(cachedAt) > 3600 // 1 hour
        }
    }
}

// MARK: - Lookup Errors

enum LookupError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound(isbn: String)
    case rateLimited
    case clientError(Int)
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case decodingFailed(String)
    case imageLoadFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid lookup URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .notFound(let isbn):
            return "No book found for ISBN: \(isbn)"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        case .clientError(let code):
            return "Client error: \(code)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .decodingFailed(let message):
            return "Failed to decode response: \(message)"
        case .imageLoadFailed:
            return "Failed to load cover image"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Environment Support

import SwiftUI

private struct ISBNLookupServiceKey: EnvironmentKey {
    static let defaultValue: ISBNLookupService? = nil
}

extension EnvironmentValues {
    var isbnLookupService: ISBNLookupService? {
        get { self[ISBNLookupServiceKey.self] }
        set { self[ISBNLookupServiceKey.self] = newValue }
    }
}

extension View {
    /// Inject ISBNLookupService into the environment
    func isbnLookupService(_ service: ISBNLookupService) -> some View {
        environment(\.isbnLookupService, service)
    }
}
