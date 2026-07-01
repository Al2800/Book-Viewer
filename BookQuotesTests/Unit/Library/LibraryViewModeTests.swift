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
