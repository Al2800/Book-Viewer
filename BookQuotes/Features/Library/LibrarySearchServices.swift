import Foundation

@MainActor
struct LibrarySearchServices {
    let searchService: SearchService
    let suggestionsService: SearchSuggestionsService

    init(searchDatabase: SearchDatabase) {
        self.searchService = SearchService(database: searchDatabase)
        self.suggestionsService = SearchSuggestionsService(searchDB: searchDatabase)
    }

    static func live() throws -> LibrarySearchServices {
        try LibrarySearchServices(searchDatabase: SearchDatabase())
    }

    func updateSuggestions(for searchText: String) async {
        await suggestionsService.getSuggestions(for: searchText)
    }

    func handlePresentationChange(isActive: Bool, searchText: String) async {
        if isActive {
            await updateSuggestions(for: searchText)
        } else {
            suggestionsService.clearSuggestions()
        }
    }

    func submitSearch(_ searchText: String) {
        suggestionsService.addToHistory(searchText)
    }

    func acceptSuggestion(_ suggestion: String) {
        suggestionsService.addToHistory(suggestion)
    }

    func refreshSearchIndex() {
        searchService.search("", scope: .all)
    }
}
