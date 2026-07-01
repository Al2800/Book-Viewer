import XCTest

@testable import BookQuotes

final class OnboardingCompletionStoreTests: XCTestCase {
    private let suiteName = "OnboardingCompletionStoreTests"
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

    func testMarkCompletedPersistsOnboardingAndFirstCaptureCoachingFlags() throws {
        let store = OnboardingCompletionStore(userDefaults: try XCTUnwrap(defaults))

        store.markCompleted()

        XCTAssertTrue(defaults.bool(forKey: "hasCompletedOnboarding"))
        XCTAssertTrue(defaults.bool(forKey: "showFirstCaptureCoaching"))
    }
}
