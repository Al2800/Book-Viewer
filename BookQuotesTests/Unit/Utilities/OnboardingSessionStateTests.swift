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

    func testSkippingSignInDoesNotPresentSubscriptionPurchase() {
        var state = OnboardingSessionState(
            flowPolicy: OnboardingFlowPolicy(
                subscriptionsEnabled: true,
                startsAtSubscriptionMediaScreen: false
            )
        )

        state.advance(to: .signIn)
        state.advanceFromSignIn()

        XCTAssertEqual(state.currentStep, .markingSetup)
    }

    func testAdvanceFromWelcomeMovesToSignIn() {
        var state = OnboardingSessionState()

        state.advanceFromWelcome()

        XCTAssertEqual(state.currentStep, .signIn)
    }

    func testAdvanceFromSubscriptionRecordsActivationAndMovesToMarkingSetup() {
        var state = OnboardingSessionState()
        state.advance(to: .subscription)

        state.advanceFromSubscription(activated: true)

        XCTAssertEqual(state.currentStep, .markingSetup)
        XCTAssertTrue(state.subscriptionActivated)
    }

    func testAdvanceFromMarkingSetupMovesSubscriberToAIConsent() {
        var state = OnboardingSessionState()
        state.advanceFromSubscription(activated: true)
        state.advance(to: .markingSetup)

        state.advanceFromMarkingSetup()

        XCTAssertEqual(state.currentStep, .aiConsent)
    }

    func testAdvanceFromMarkingSetupCompletesLocalOnlyOnboardingWithoutConsentPrompt() {
        var state = OnboardingSessionState()
        state.advance(to: .markingSetup)

        state.advanceFromMarkingSetup()

        XCTAssertEqual(state.currentStep, .complete)
        XCTAssertFalse(state.subscriptionActivated)
    }

    func testAdvanceFromAIConsentMovesToComplete() {
        var state = OnboardingSessionState()
        state.advance(to: .aiConsent)

        state.advanceFromAIConsent()

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
