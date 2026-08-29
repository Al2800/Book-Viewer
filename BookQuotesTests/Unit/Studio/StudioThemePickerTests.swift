import XCTest
import SwiftUI
@testable import BookQuotes

final class StudioThemePickerTests: XCTestCase {
    func testAllStudioThemesHaveUniqueIdentities() {
        let themes = StudioTheme.allCases
        let ids = Set(themes.map(\.id))
        XCTAssertEqual(ids.count, themes.count, "Each theme must have a unique identifier")
    }

    func testStudioThemePropertiesProduceValidColors() {
        for theme in StudioTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
            _ = theme.cardBackground
            _ = theme.textColor
            _ = theme.secondaryTextColor
            _ = theme.accentColor
            _ = theme.borderColor
        }
    }

    func testStudioAspectRatiosProducePositiveRatioValues() {
        for aspect in StudioAspectRatio.allCases {
            XCTAssertGreaterThan(aspect.ratioValue, 0)
            XCTAssertGreaterThan(aspect.targetSize.width, 0)
            XCTAssertGreaterThan(aspect.targetSize.height, 0)
            XCTAssertFalse(aspect.displayName.isEmpty)
        }
    }

    func testStoryAspectRatioIsNineSixteenths() {
        let story = StudioAspectRatio.story
        XCTAssertEqual(story.ratioValue, 9.0 / 16.0, accuracy: 0.001)
    }

    func testSquareAspectRatioIsOne() {
        let square = StudioAspectRatio.square
        XCTAssertEqual(square.ratioValue, 1.0, accuracy: 0.001)
    }

    func testPortraitAspectRatioIsFourFifths() {
        let portrait = StudioAspectRatio.portrait
        XCTAssertEqual(portrait.ratioValue, 4.0 / 5.0, accuracy: 0.001)
    }
}
