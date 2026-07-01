import XCTest

@testable import BookQuotes

@MainActor
final class LibrarySearchServicesTests: XCTestCase {
    func testSearchSubmissionAndPresentationUpdateSuggestionsHistory() async throws {
        let database = try SearchDatabase(inMemory: true)
        let services = LibrarySearchServices(searchDatabase: database)

        services.suggestionsService.clearHistory()
        services.submitSearch("  habits  ")

        XCTAssertEqual(services.suggestionsService.getRecentSearches().first, "habits")

        await services.handlePresentationChange(isActive: true, searchText: "")
        XCTAssertEqual(services.suggestionsService.suggestions.first, .recent("habits"))

        await services.handlePresentationChange(isActive: false, searchText: "habits")
        XCTAssertTrue(services.suggestionsService.suggestions.isEmpty)
    }
}
