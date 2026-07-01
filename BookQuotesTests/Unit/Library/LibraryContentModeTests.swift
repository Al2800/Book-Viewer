import XCTest

@testable import BookQuotes

final class LibraryContentModeTests: XCTestCase {
    func testActiveNonEmptySearchShowsSearchResultsEvenWhenLibraryIsEmpty() {
        let mode = LibraryContentMode.resolve(
            isSearchActive: true,
            searchText: "habits",
            bookCount: 0
        )

        XCTAssertEqual(mode, .searchResults)
    }

    func testActiveEmptySearchFallsBackToEmptyLibraryWhenThereAreNoBooks() {
        let mode = LibraryContentMode.resolve(
            isSearchActive: true,
            searchText: "",
            bookCount: 0
        )

        XCTAssertEqual(mode, .emptyLibrary)
    }

    func testInactiveSearchShowsLibraryWhenBooksExistEvenIfSearchTextRemains() {
        let mode = LibraryContentMode.resolve(
            isSearchActive: false,
            searchText: "habits",
            bookCount: 2
        )

        XCTAssertEqual(mode, .library)
    }

    func testInactiveSearchShowsEmptyLibraryWhenNoBooksExist() {
        let mode = LibraryContentMode.resolve(
            isSearchActive: false,
            searchText: "",
            bookCount: 0
        )

        XCTAssertEqual(mode, .emptyLibrary)
    }
}
