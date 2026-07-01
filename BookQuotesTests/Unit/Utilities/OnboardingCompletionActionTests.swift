import XCTest

@testable import BookQuotes

final class OnboardingCompletionActionTests: XCTestCase {
    private let suiteName = "OnboardingCompletionActionTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testCompleteMarksSessionAndPersistsCompletionFlags() throws {
        var sessionState = OnboardingSessionState()
        let action = OnboardingCompletionAction(
            completionStore: OnboardingCompletionStore(userDefaults: try XCTUnwrap(defaults))
        )

        action.complete(sessionState: &sessionState)

        XCTAssertTrue(sessionState.isCompleting)
        XCTAssertTrue(defaults.bool(forKey: "hasCompletedOnboarding"))
        XCTAssertTrue(defaults.bool(forKey: "showFirstCaptureCoaching"))
    }
}
