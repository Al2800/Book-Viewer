import XCTest

@testable import BookQuotes

final class LibraryViewModeTests: XCTestCase {
    func testGridModePreservesStoredValueAndPresentation() {
        let mode = LibraryViewMode.grid

        XCTAssertEqual(mode.rawValue, "grid")
        XCTAssertEqual(mode.systemImageName, "square.grid.2x2")
        XCTAssertEqual(mode.summaryText, "Grid View")
    }

    func testListModePreservesStoredValueAndPresentation() {
        let mode = LibraryViewMode.list

        XCTAssertEqual(mode.rawValue, "list")
        XCTAssertEqual(mode.systemImageName, "list.bullet")
        XCTAssertEqual(mode.summaryText, "List View")
    }
}

final class LibrarySortOrderTests: XCTestCase {

    func testRecentSortsNewestFirst() {
        let older = book(title: "Older", dateAdded: date(1))
        let newer = book(title: "Newer", dateAdded: date(3))
        let middle = book(title: "Middle", dateAdded: date(2))

        let sorted = LibrarySortOrder.recent.sorted([older, newer, middle])

        XCTAssertEqual(sorted.map(\.title), ["Newer", "Middle", "Older"])
    }

    func testTitleSortsAlphabeticallyIgnoringCase() {
        let zebra = book(title: "zebra")
        let atomic = book(title: "Atomic Habits")
        let meditations = book(title: "meditations")

        let sorted = LibrarySortOrder.title.sorted([zebra, atomic, meditations])

        XCTAssertEqual(sorted.map(\.title), ["Atomic Habits", "meditations", "zebra"])
    }

    func testAuthorSortsAlphabeticallyIgnoringCase() {
        let clear = book(title: "A", author: "james clear")
        let aurelius = book(title: "B", author: "Marcus Aurelius")
        let butler = book(title: "C", author: "Octavia Butler")

        let sorted = LibrarySortOrder.author.sorted([butler, clear, aurelius])

        XCTAssertEqual(sorted.map(\.author), ["james clear", "Marcus Aurelius", "Octavia Butler"])
    }

    private func book(title: String, author: String = "Author", dateAdded: Date = Date()) -> Book {
        let book = Book(title: title, author: author)
        book.dateAdded = dateAdded
        return book
    }

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: offset * 86_400)
    }
}
