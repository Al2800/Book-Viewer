import XCTest

@testable import BookQuotes

final class OnboardingWelcomeCarouselStateTests: XCTestCase {
    func testFirstPageShowsSkipAndContinue() {
        let state = OnboardingWelcomeCarouselState(
            currentPage: 0,
            pageCount: 3
        )

        XCTAssertTrue(state.showsSkipButton)
        XCTAssertEqual(state.primaryButtonTitle, "Continue")
    }

    func testAdvanceBeforeLastPageMovesToNextPage() {
        var state = OnboardingWelcomeCarouselState(
            currentPage: 0,
            pageCount: 3
        )

        let action = state.advance()

        XCTAssertEqual(action, .showNextPage)
        XCTAssertEqual(state.currentPage, 1)
    }

    func testLastPageHidesSkipAndCompletes() {
        var state = OnboardingWelcomeCarouselState(
            currentPage: 2,
            pageCount: 3
        )

        let action = state.advance()

        XCTAssertFalse(state.showsSkipButton)
        XCTAssertEqual(state.primaryButtonTitle, "Get Started")
        XCTAssertEqual(action, .complete)
        XCTAssertEqual(state.currentPage, 2)
    }
}
