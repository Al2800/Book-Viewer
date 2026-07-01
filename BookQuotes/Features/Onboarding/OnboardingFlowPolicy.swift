import Foundation

struct OnboardingFlowPolicy: Equatable {
    let subscriptionsEnabled: Bool
    let startsAtSubscriptionMediaScreen: Bool

    static var current: OnboardingFlowPolicy {
        OnboardingFlowPolicy(
            subscriptionsEnabled: AppReleaseConfiguration.subscriptionsEnabled,
            startsAtSubscriptionMediaScreen: UITestConfiguration.shouldOpenSubscriptionMediaScreen
        )
    }

    var initialStep: OnboardingStep {
        startsAtSubscriptionMediaScreen ? .subscription : .welcome
    }

    var stepAfterSignIn: OnboardingStep {
        subscriptionsEnabled ? .subscription : .markingSetup
    }
}
