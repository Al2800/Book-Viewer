import XCTest

@testable import BookQuotes

final class OnboardingMarkingSelectionStateTests: XCTestCase {
    func testDefaultSelectionIncludesUnderlineAndHighlight() {
        let state = OnboardingMarkingSelectionState()

        XCTAssertTrue(state.isSelected(.underline))
        XCTAssertTrue(state.isSelected(.highlight))
        XCTAssertFalse(state.isSelected(.marginLine))
    }

    func testToggleSelectedStyleRemovesIt() {
        var state = OnboardingMarkingSelectionState()

        state.toggle(.underline)

        XCTAssertFalse(state.isSelected(.underline))
        XCTAssertTrue(state.isSelected(.highlight))
    }

    func testToggleUnselectedStyleAddsIt() {
        var state = OnboardingMarkingSelectionState()

        state.toggle(.marginLine)

        XCTAssertTrue(state.isSelected(.marginLine))
        XCTAssertTrue(state.isSelected(.underline))
        XCTAssertTrue(state.isSelected(.highlight))
    }

    func testMixedExtractionResultIsNotAConfigurableStyle() {
        XCTAssertFalse(MarkingType.configurableCases.contains(.mixed))
    }
}
