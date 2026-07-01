import Foundation

enum OnboardingStep: Equatable {
    case welcome
    case signIn
    case subscription
    case markingSetup
    case complete
}

struct OnboardingSessionState: Equatable {
    private let flowPolicy: OnboardingFlowPolicy

    private(set) var currentStep: OnboardingStep
    private(set) var signedInUser: User?
    private(set) var isCompleting = false

    init(flowPolicy: OnboardingFlowPolicy = .current) {
        self.flowPolicy = flowPolicy
        self.currentStep = flowPolicy.initialStep
    }

    mutating func advance(to step: OnboardingStep) {
        currentStep = step
    }

    mutating func advanceFromWelcome() {
        currentStep = .signIn
    }

    mutating func signedIn(_ user: User) {
        signedInUser = user
    }

    mutating func advanceFromSignIn() {
        currentStep = flowPolicy.stepAfterSignIn
    }

    mutating func advanceFromSubscription() {
        currentStep = .markingSetup
    }

    mutating func advanceFromMarkingSetup() {
        currentStep = .complete
    }

    mutating func complete() {
        isCompleting = true
    }
}
