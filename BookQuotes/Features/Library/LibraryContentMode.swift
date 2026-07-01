import Foundation

enum LibraryContentMode: Equatable {
    case searchResults
    case emptyLibrary
    case library

    static func resolve(
        isSearchActive: Bool,
        searchText: String,
        bookCount: Int
    ) -> LibraryContentMode {
        if isSearchActive && !searchText.isEmpty {
            return .searchResults
        }

        return bookCount == 0 ? .emptyLibrary : .library
    }
}
