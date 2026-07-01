import XCTest

@testable import BookQuotes

final class OnboardingSignInCopyPolicyTests: XCTestCase {
    func testSubscriptionEnabledCopyPromotesTrialAndAIExtraction() {
        let policy = OnboardingSignInCopyPolicy(
            subscriptionsEnabled: true,
            cloudSyncEnabled: false
        )

        XCTAssertEqual(
            policy.description,
            "Sign in to start your 7-day free trial and unlock AI extraction while keeping your library stored on this device"
        )
    }

    func testCloudSyncCopyWhenSubscriptionsAreDisabled() {
        let policy = OnboardingSignInCopyPolicy(
            subscriptionsEnabled: false,
            cloudSyncEnabled: true
        )

        XCTAssertEqual(
            policy.description,
            "Sign in to sync your library across devices and unlock all features"
        )
    }

    func testLocalLibraryCopyWhenSubscriptionsAndCloudSyncAreDisabled() {
        let policy = OnboardingSignInCopyPolicy(
            subscriptionsEnabled: false,
            cloudSyncEnabled: false
        )

        XCTAssertEqual(
            policy.description,
            "Sign in to enable AI extraction while keeping your library stored on this device"
        )
    }
}
