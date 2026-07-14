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

    func testManualSkipIsAllowedOnDeviceWithoutLaunchArgument() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: false,
            isUITesting: false,
            shouldSkipAuthArgument: false
        )

        XCTAssertTrue(policy.allowsManualSkip)
    }

    func testSimulatorAutoSkipIsDisabledDuringUITesting() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: true,
            isUITesting: true,
            shouldSkipAuthArgument: true
        )

        XCTAssertFalse(policy.shouldAutoSkipAuth)
    }

    func testSimulatorDoesNotAutoSkipAuthOutsideUITesting() {
        let policy = OnboardingAuthSkipPolicy(
            isSimulator: true,
            isUITesting: false,
            shouldSkipAuthArgument: false
        )

        XCTAssertFalse(policy.shouldAutoSkipAuth)
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
