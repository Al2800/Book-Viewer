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

final class DailyPassageTests: XCTestCase {

    func testReturnsNilWhenThereAreNoQuotes() {
        XCTAssertNil(DailyPassage.passage(from: [], on: Date()))
    }

    func testPicksSameQuoteForSameDay() {
        let quotes = (0..<5).map { Quote(text: "Quote \($0)") }
        let morning = date(day: 10, hour: 8)
        let evening = date(day: 10, hour: 22)

        let first = DailyPassage.passage(from: quotes, on: morning)
        let second = DailyPassage.passage(from: quotes, on: evening)

        XCTAssertEqual(first?.id, second?.id)
    }

    func testPickIsStableRegardlessOfInputOrder() {
        let quotes = (0..<5).map { Quote(text: "Quote \($0)") }
        let day = date(day: 12, hour: 9)

        let fromOriginal = DailyPassage.passage(from: quotes, on: day)
        let fromReversed = DailyPassage.passage(from: quotes.reversed(), on: day)

        XCTAssertEqual(fromOriginal?.id, fromReversed?.id)
    }

    func testPrefersFavoritesWhenAnyExist() {
        let plain = Quote(text: "Plain")
        let favorite = Quote(text: "Favorite")
        favorite.isFavorite = true

        let picked = DailyPassage.passage(from: [plain, favorite], on: Date())

        XCTAssertEqual(picked?.text, "Favorite")
    }

    func testFallsBackToAllQuotesWhenNoFavorites() {
        let single = Quote(text: "Only quote")

        let picked = DailyPassage.passage(from: [single], on: Date())

        XCTAssertEqual(picked?.text, "Only quote")
    }

    private func date(day: Int, hour: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components) ?? Date()
    }
}
