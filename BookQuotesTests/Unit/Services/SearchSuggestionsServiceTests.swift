import XCTest

@testable import BookQuotes

// MARK: - SearchSuggestionsServiceTests

@MainActor
final class SearchSuggestionsServiceTests: FTS5TestCase {

    override func setUp() async throws {
        try await super.setUp()
        // SearchSuggestionsService uses @AppStorage("recentSearches"), which persists across tests.
        // Make these tests hermetic by clearing the key.
        UserDefaults.standard.removeObject(forKey: "recentSearches")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "recentSearches")
        try await super.tearDown()
    }

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
