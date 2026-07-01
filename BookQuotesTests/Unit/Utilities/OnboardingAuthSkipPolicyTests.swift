import XCTest

@testable import BookQuotes

final class OnboardingAuthSkipPolicyTests: XCTestCase {
    func testManualSkipIsAllowedOnSimulatorWithoutLaunchArgument() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: true,
            isUITesting: true,
            shouldSkipAuthArgument: false
        )

        XCTAssertTrue(policy.allowsManualSkip)
    }

    func testManualSkipOnDeviceFollowsLaunchArgument() {
        let disabled = OnboardingAuthSkipPolicy(
            isSimulator: false,
            isUITesting: false,
            shouldSkipAuthArgument: false
        )
        let enabled = OnboardingAuthSkipPolicy(
            isSimulator: false,
            isUITesting: true,
            shouldSkipAuthArgument: true
        )

        XCTAssertFalse(disabled.allowsManualSkip)
        XCTAssertTrue(enabled.allowsManualSkip)
    }

    func testSimulatorAutoSkipIsDisabledDuringUITesting() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: true,
            isUITesting: true,
            shouldSkipAuthArgument: true
        )

        XCTAssertFalse(policy.shouldAutoSkipAuth)
    }

    func testSimulatorAutoSkipIsEnabledOutsideUITesting() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: true,
            isUITesting: false,
            shouldSkipAuthArgument: false
        )

        XCTAssertTrue(policy.shouldAutoSkipAuth)
    }

    func testDeviceNeverAutoSkipsAuth() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: false,
            isUITesting: false,
            shouldSkipAuthArgument: true
        )

        XCTAssertFalse(policy.shouldAutoSkipAuth)
    }
}
