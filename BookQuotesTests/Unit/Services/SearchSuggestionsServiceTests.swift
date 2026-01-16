import XCTest

@testable import BookQuotes

// MARK: - SearchSuggestionsServiceTests

@MainActor
final class SearchSuggestionsServiceTests: FTS5TestCase {

    func testAddToHistoryDedupes() {
        let service = SearchSuggestionsService(searchDB: searchDatabase)
        service.addToHistory("Focus")
        service.addToHistory("focus")

        let recent = service.getRecentSearches()
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first, "focus")
    }

    func testRemoveFromHistory() {
        let service = SearchSuggestionsService(searchDB: searchDatabase)
        service.addToHistory("Habits")
        service.addToHistory("Systems")

        service.removeFromHistory("Habits")
        let recent = service.getRecentSearches()

        XCTAssertFalse(recent.contains("Habits"))
        XCTAssertTrue(recent.contains("Systems"))
    }

    func testClearHistoryRemovesRecentSuggestions() async {
        let service = SearchSuggestionsService(searchDB: searchDatabase)
        service.addToHistory("Reading")
        await service.getSuggestions(for: "")
        XCTAssertFalse(service.suggestions.isEmpty)

        service.clearHistory()
        XCTAssertTrue(service.getRecentSearches().isEmpty)
        XCTAssertTrue(service.suggestions.isEmpty)
    }
}
