import XCTest
@testable import BookQuotes

final class TabTests: XCTestCase {

    func testAllFourLegacyTabsAreDefined() {
        let tabs = Tab.allCases
        XCTAssertEqual(tabs.count, 4)
        XCTAssertEqual(tabs, [.library, .capture, .studio, .settings])
    }

    func testLegacyTabTitles() {
        XCTAssertEqual(Tab.library.title, "Library")
        XCTAssertEqual(Tab.capture.title, "Capture")
        XCTAssertEqual(Tab.studio.title, "Studio")
        XCTAssertEqual(Tab.settings.title, "Settings")
    }

    func testLegacyTabSystemImages() {
        XCTAssertEqual(Tab.library.systemImage, "books.vertical")
        XCTAssertEqual(Tab.capture.systemImage, "camera")
        XCTAssertEqual(Tab.studio.systemImage, "sparkles.rectangle.stack")
        XCTAssertEqual(Tab.settings.systemImage, "gear")
    }

    func testV2ShellDefinesReadingCaptureAndStudio() {
        XCTAssertEqual(V2Tab.allCases, [.reading, .capture, .studio])
        XCTAssertEqual(V2Tab.reading.title, "Reading")
        XCTAssertEqual(V2Tab.capture.title, "Capture")
        XCTAssertEqual(V2Tab.studio.title, "Studio")
        XCTAssertEqual(V2Tab.studio.systemImage, "sparkles.rectangle.stack")
    }

    func testV2TabIdentifiersAreStableAndUnique() {
        let identifiers = V2Tab.allCases.map(\.accessibilityIdentifier)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertEqual(V2Tab.reading.accessibilityIdentifier, "v2_reading_tab")
        XCTAssertEqual(V2Tab.capture.accessibilityIdentifier, "v2_capture_tab")
        XCTAssertEqual(V2Tab.studio.accessibilityIdentifier, "v2_studio_tab")
    }

    func testProductExperienceUsesRotatedPreferenceKey() {
        XCTAssertEqual(ProductExperience.v2StorageKey, "product_experience_prefer_v2")
    }

    func testProductExperienceIsOffWithoutStoredValueOrArgument() {
        XCTAssertFalse(ProductExperience.usesV2(storedValue: false, arguments: []))
    }

    func testProductExperienceCanBeEnabledByStoredValue() {
        XCTAssertTrue(ProductExperience.usesV2(storedValue: true, arguments: []))
    }

    func testProductExperienceCanBeEnabledByLaunchArgument() {
        XCTAssertTrue(ProductExperience.usesV2(
            storedValue: false,
            arguments: [ProductExperience.v2LaunchArgument]
        ))
    }

    func testProductExperienceLegacyLaunchArgumentDisablesV2() {
        XCTAssertFalse(ProductExperience.usesV2(
            storedValue: true,
            arguments: [ProductExperience.legacyLaunchArgument]
        ))
    }

    func testProductExperienceDefaultsOnOutsideUITests() {
        XCTAssertEqual(ProductExperience.defaultEnabled, !UITestConfiguration.isUITesting)
    }

    func testStudioThemesAndAspectRatios() {
        XCTAssertEqual(StudioTheme.allCases.count, 7)
        XCTAssertEqual(StudioAspectRatio.allCases.count, 3)

        for theme in StudioTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
        }

        for aspect in StudioAspectRatio.allCases {
            XCTAssertGreaterThan(aspect.ratioValue, 0)
        }
    }
}
