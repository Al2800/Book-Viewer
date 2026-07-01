import XCTest

@testable import BookQuotes

final class OnboardingSessionStateTests: XCTestCase {
    func testStartsAtPolicyInitialStep() {
        let state = OnboardingSessionState(
            flowPolicy: OnboardingFlowPolicy(
                subscriptionsEnabled: true,
                startsAtSubscriptionMediaScreen: true
            )
        )

        XCTAssertEqual(state.currentStep, .subscription)
        XCTAssertNil(state.signedInUser)
        XCTAssertFalse(state.isCompleting)
    }

    func testAdvanceFromSignInStoresUserAndUsesPolicyRoute() {
        var state = OnboardingSessionState(
            flowPolicy: OnboardingFlowPolicy(
                subscriptionsEnabled: false,
                startsAtSubscriptionMediaScreen: false
            )
        )
        let user = User(
            id: "reader-1",
            email: "reader@example.com",
            displayName: nil,
            subscriptionStatus: .none
        )

        state.signedIn(user)
        state.advanceFromSignIn()

        XCTAssertEqual(state.signedInUser, user)
        XCTAssertEqual(state.currentStep, .markingSetup)
    }

    func testAdvanceFromWelcomeMovesToSignIn() {
        var state = OnboardingSessionState()

        state.advanceFromWelcome()

        XCTAssertEqual(state.currentStep, .signIn)
    }

    func testAdvanceFromSubscriptionMovesToMarkingSetup() {
        var state = OnboardingSessionState()
        state.advance(to: .subscription)

        state.advanceFromSubscription()

        XCTAssertEqual(state.currentStep, .markingSetup)
    }

    func testAdvanceFromMarkingSetupMovesToComplete() {
        var state = OnboardingSessionState()
        state.advance(to: .markingSetup)

        state.advanceFromMarkingSetup()

        XCTAssertEqual(state.currentStep, .complete)
    }

    func testAdvanceToExplicitStepKeepsSignedInUser() {
        var state = OnboardingSessionState()
        let user = User(
            id: "reader-2",
            email: "reader-2@example.com",
            displayName: nil,
            subscriptionStatus: .none
        )

        state.signedIn(user)
        state.advance(to: .markingSetup)

        XCTAssertEqual(state.currentStep, .markingSetup)
        XCTAssertEqual(state.signedInUser, user)
    }

    func testCompleteMarksCompletionInProgress() {
        var state = OnboardingSessionState()

        state.complete()

        XCTAssertTrue(state.isCompleting)
    }
}
