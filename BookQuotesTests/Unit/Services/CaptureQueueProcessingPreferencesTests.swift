import XCTest

@testable import BookQuotes

final class CaptureQueueProcessingPreferencesTests: XCTestCase {
    private let suiteName = "CaptureQueueProcessingPreferencesTests"
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

    func testAutoProcessDefaultsToEnabledWhenUnset() throws {
        let preferences = CaptureQueueProcessingPreferences(
            userDefaults: try XCTUnwrap(defaults)
        )

        XCTAssertTrue(preferences.isAutoProcessEnabled)
    }

    func testAutoProcessFollowsStoredPreference() throws {
        let defaults = try XCTUnwrap(defaults)
        let preferences = CaptureQueueProcessingPreferences(userDefaults: defaults)

        defaults.set(false, forKey: CaptureQueueProcessingPreferences.autoProcessQueueKey)
        XCTAssertFalse(preferences.isAutoProcessEnabled)

        defaults.set(true, forKey: CaptureQueueProcessingPreferences.autoProcessQueueKey)
        XCTAssertTrue(preferences.isAutoProcessEnabled)
    }
}
