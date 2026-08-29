import XCTest
@testable import BookQuotes

final class TabTests: XCTestCase {

    func testAllFourTabsAreDefined() {
        let tabs = Tab.allCases
        XCTAssertEqual(tabs.count, 4)
        XCTAssertEqual(tabs, [.library, .capture, .studio, .settings])
    }

    func testTabTitles() {
        XCTAssertEqual(Tab.library.title, "Library")
        XCTAssertEqual(Tab.capture.title, "Capture")
        XCTAssertEqual(Tab.studio.title, "Studio")
        XCTAssertEqual(Tab.settings.title, "Settings")
    }

    func testTabSystemImages() {
        XCTAssertEqual(Tab.library.systemImage, "books.vertical")
        XCTAssertEqual(Tab.capture.systemImage, "camera")
        XCTAssertEqual(Tab.studio.systemImage, "sparkles.rectangle.stack")
        XCTAssertEqual(Tab.settings.systemImage, "gear")
    }

    func testStudioThemesAndAspectRatios() {
        XCTAssertEqual(StudioTheme.allCases.count, 5)
        XCTAssertEqual(StudioAspectRatio.allCases.count, 3)

        for theme in StudioTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
        }

        for aspect in StudioAspectRatio.allCases {
            XCTAssertGreaterThan(aspect.ratioValue, 0)
        }
    }
}
