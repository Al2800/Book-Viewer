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
            "Sign in for a free trial and remote AI features. You can continue locally and sign in later."
        )
    }

    func testCloudSyncCopyWhenSubscriptionsAreDisabled() {
        let policy = OnboardingSignInCopyPolicy(
            subscriptionsEnabled: false,
            cloudSyncEnabled: true
        )

        XCTAssertEqual(
            policy.description,
            "Sign in to sync your library across devices. You can continue locally and sign in later."
        )
    }

    func testLocalLibraryCopyWhenSubscriptionsAndCloudSyncAreDisabled() {
        let policy = OnboardingSignInCopyPolicy(
            subscriptionsEnabled: false,
            cloudSyncEnabled: false
        )

        XCTAssertEqual(
            policy.description,
            "Your library works on this device without an account. Sign in later for remote AI features."
        )
    }
}
