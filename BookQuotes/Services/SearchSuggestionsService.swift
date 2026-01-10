import Foundation
import SwiftUI

// MARK: - SearchSuggestion

/// Types of search suggestions shown as users type
enum SearchSuggestion: Identifiable, Hashable {
    case recent(String)
    case bookTitle(String, UUID)
    case author(String)
    case popularTerm(String, Int)

    var id: String {
        switch self {
        case .recent(let s): return "recent:\(s)"
        case .bookTitle(let s, let id): return "book:\(s):\(id.uuidString)"
        case .author(let s): return "author:\(s)"
        case .popularTerm(let s, _): return "term:\(s)"
        }
    }

    var text: String {
        switch self {
        case .recent(let s), .bookTitle(let s, _), .author(let s), .popularTerm(let s, _):
            return s
        }
    }

    var icon: String {
        switch self {
        case .recent: return "clock"
        case .bookTitle: return "book"
        case .author: return "person"
        case .popularTerm: return "magnifyingglass"
        }
    }

    var isRecent: Bool {
        if case .recent = self { return true }
        return false
    }
}

// MARK: - SearchSuggestionsService

/// Service providing search suggestions, history, and did-you-mean corrections
@MainActor
@Observable
final class SearchSuggestionsService {

    // MARK: - Dependencies

    private let searchDB: SearchDatabase

    // MARK: - Configuration

    private let maxHistory = 20
    private let maxSuggestions = 8

    // MARK: - Storage

    @ObservationIgnored
    @AppStorage("recentSearches") private var recentSearchesData: Data = Data()

    // MARK: - State

    private(set) var suggestions: [SearchSuggestion] = []
    private(set) var isLoading = false

    // MARK: - Initialization

    init(searchDB: SearchDatabase) {
        self.searchDB = searchDB
    }

    // MARK: - Suggestions

    /// Get suggestions as user types
    func getSuggestions(for prefix: String) async {
        let trimmedPrefix = prefix.trimmingCharacters(in: .whitespaces)

        guard trimmedPrefix.count >= 1 else {
            // Show recent searches when empty
            suggestions = getRecentSearches().map { .recent($0) }
            return
        }

        isLoading = true
        defer { isLoading = false }

        var results: [SearchSuggestion] = []

        // 1. Recent searches matching prefix
        let matchingRecent = getRecentSearches()
            .filter { $0.localizedCaseInsensitiveContains(trimmedPrefix) }
            .prefix(3)
            .map { SearchSuggestion.recent($0) }
        results.append(contentsOf: matchingRecent)

        // 2. Book titles matching prefix
        do {
            let matchingBooks = try await searchDB.bookTitlesMatching(prefix: trimmedPrefix, limit: 3)
            results.append(contentsOf: matchingBooks)
        } catch {
            // Continue with other suggestions on error
        }

        // 3. Authors matching prefix
        do {
            let matchingAuthors = try await searchDB.authorsMatching(prefix: trimmedPrefix, limit: 2)
            results.append(contentsOf: matchingAuthors)
        } catch {
            // Continue with other suggestions on error
        }

        // 4. Popular terms from quotes (if we have room)
        if results.count < 5 {
            do {
                let popularTerms = try await searchDB.popularTermsMatching(
                    prefix: trimmedPrefix,
                    limit: 3
                )
                results.append(contentsOf: popularTerms)
            } catch {
                // Continue without popular terms on error
            }
        }

        // Deduplicate and limit
        var seen = Set<String>()
        suggestions = results.filter { suggestion in
            let text = suggestion.text.lowercased()
            if seen.contains(text) { return false }
            seen.insert(text)
            return true
        }.prefix(maxSuggestions).map { $0 }
    }

    /// Clear suggestions
    func clearSuggestions() {
        suggestions = []
    }

    // MARK: - Search History

    /// Save a search to history
    func addToHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var recent = getRecentSearches()
        recent.removeAll { $0.lowercased() == trimmed.lowercased() }
        recent.insert(trimmed, at: 0)
        recent = Array(recent.prefix(maxHistory))
        saveRecentSearches(recent)
    }

    /// Remove a specific search from history
    func removeFromHistory(_ query: String) {
        var recent = getRecentSearches()
        recent.removeAll { $0.lowercased() == query.lowercased() }
        saveRecentSearches(recent)

        // Update suggestions if showing
        suggestions = suggestions.filter {
            if case .recent(let text) = $0 {
                return text.lowercased() != query.lowercased()
            }
            return true
        }
    }

    /// Clear all search history
    func clearHistory() {
        saveRecentSearches([])
        // Remove recent suggestions
        suggestions = suggestions.filter { !$0.isRecent }
    }

    /// Get recent searches
    func getRecentSearches() -> [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private func saveRecentSearches(_ searches: [String]) {
        recentSearchesData = (try? JSONEncoder().encode(searches)) ?? Data()
    }

    // MARK: - Did You Mean

    /// Suggest correction for likely typos
    func didYouMean(_ query: String) async -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 4 else { return nil }

        do {
            return try await searchDB.didYouMean(trimmed)
        } catch {
            return nil
        }
    }
}
