import XCTest

@testable import BookQuotes

final class OnboardingFlowPolicyTests: XCTestCase {
    func testInitialStep_DefaultsToWelcome() {
        let policy = OnboardingFlowPolicy(
            subscriptionsEnabled: true,
            startsAtSubscriptionMediaScreen: false
        )

        XCTAssertEqual(policy.initialStep, .welcome)
    }

    func testInitialStep_CanStartAtSubscriptionForMediaCapture() {
        let policy = OnboardingFlowPolicy(
            subscriptionsEnabled: true,
            startsAtSubscriptionMediaScreen: true
        )

        XCTAssertEqual(policy.initialStep, .subscription)
    }

    func testStepAfterSignIn_UsesSubscriptionWhenEnabled() {
        let policy = OnboardingFlowPolicy(
            subscriptionsEnabled: true,
            startsAtSubscriptionMediaScreen: false
        )

        XCTAssertEqual(policy.stepAfterSignIn, .subscription)
    }

    func testStepAfterSignIn_SkipsSubscriptionWhenDisabled() {
        let policy = OnboardingFlowPolicy(
            subscriptionsEnabled: false,
            startsAtSubscriptionMediaScreen: false
        )

        XCTAssertEqual(policy.stepAfterSignIn, .markingSetup)
    }
}
