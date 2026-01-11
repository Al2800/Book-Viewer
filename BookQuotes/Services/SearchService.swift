import Foundation
import SwiftUI
import SwiftData

// MARK: - SearchService

/// Observable search service with debounced FTS5 full-text search.
/// Provides instant-as-you-type search with relevance ranking.
@MainActor
@Observable
final class SearchService {
    // MARK: - Published State

    /// Current search results
    private(set) var results: SearchResults = .empty

    /// Whether a search is currently in progress
    private(set) var isSearching = false

    /// Last error that occurred during search
    private(set) var lastError: SearchError?

    // MARK: - Private State

    private let searchDB: SearchDatabase
    private var currentTask: Task<Void, Never>?
    private let debounceInterval: Duration = .milliseconds(150)

    // MARK: - Initialization

    init() throws {
        self.searchDB = try SearchDatabase()
    }

    /// For testing with a custom database
    init(database: SearchDatabase) {
        self.searchDB = database
    }

    // MARK: - Search API

    /// Perform a debounced search with the given query and scope.
    /// Results are automatically published to the `results` property.
    func search(_ query: String, scope: SearchScope = .all) {
        // Cancel any pending search
        currentTask?.cancel()

        // Clear results for empty query
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = .empty
            isSearching = false
            lastError = nil
            return
        }

        currentTask = Task { [weak self] in
            guard let self = self else { return }

            // Debounce to avoid excessive searches while typing
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }

            self.isSearching = true
            self.lastError = nil
            defer { self.isSearching = false }

            do {
                let searchResults = try await searchDB.search(query: query, scope: scope)

                // Check for cancellation before updating results
                guard !Task.isCancelled else { return }
                self.results = searchResults
            } catch let error as SearchError {
                guard !Task.isCancelled else { return }
                self.lastError = error
                self.results = .empty
            } catch {
                guard !Task.isCancelled else { return }
                self.lastError = .queryFailed(error.localizedDescription)
                self.results = .empty
            }
        }
    }

    /// Perform an immediate search without debouncing.
    /// Useful for programmatic searches or when immediate results are needed.
    func searchImmediate(_ query: String, scope: SearchScope = .all) async {
        currentTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = .empty
            isSearching = false
            return
        }

        isSearching = true
        lastError = nil

        do {
            let searchResults = try await searchDB.search(query: query, scope: scope)
            results = searchResults
        } catch let error as SearchError {
            lastError = error
            results = .empty
        } catch {
            lastError = .queryFailed(error.localizedDescription)
            results = .empty
        }

        isSearching = false
    }

    /// Cancel any pending search operation
    func cancelSearch() {
        currentTask?.cancel()
        currentTask = nil
        isSearching = false
    }

    /// Clear current results
    func clearResults() {
        cancelSearch()
        results = .empty
        lastError = nil
    }

    // MARK: - Index Management

    /// Index a quote for search
    func indexQuote(_ quote: Quote, book: Book) async {
        do {
            try await searchDB.indexQuote(quote, book: book)
        } catch {
            lastError = .indexingFailed("Failed to index quote: \(error.localizedDescription)")
        }
    }

    /// Index a book for search
    func indexBook(_ book: Book) async {
        do {
            try await searchDB.indexBook(book)
        } catch {
            lastError = .indexingFailed("Failed to index book: \(error.localizedDescription)")
        }
    }

    /// Remove a quote from the search index
    func removeQuoteFromIndex(id: UUID) async {
        do {
            try await searchDB.removeQuote(id: id)
        } catch {
            // Silently fail - quote might not be indexed
        }
    }

    /// Remove a book and its quotes from the search index
    func removeBookFromIndex(id: UUID) async {
        do {
            try await searchDB.removeBook(id: id)
        } catch {
            // Silently fail - book might not be indexed
        }
    }

    /// Rebuild the entire search index from the given books.
    /// Call this on first launch or when index corruption is suspected.
    func rebuildIndex(books: [Book]) async {
        do {
            try await searchDB.rebuildIndex(books: books)
        } catch {
            lastError = .indexingFailed("Failed to rebuild index: \(error.localizedDescription)")
        }
    }

    // MARK: - Statistics

    /// Get the number of indexed quotes
    var indexedQuotesCount: Int {
        get async {
            (try? await searchDB.quotesCount()) ?? 0
        }
    }

    /// Get the number of indexed books
    var indexedBooksCount: Int {
        get async {
            (try? await searchDB.booksCount()) ?? 0
        }
    }
}

// MARK: - Environment Key

private struct SearchServiceKey: EnvironmentKey {
    static let defaultValue: SearchService? = nil
}

extension EnvironmentValues {
    var searchService: SearchService? {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject SearchService into the environment
    func searchService(_ service: SearchService) -> some View {
        environment(\.searchService, service)
    }
}
