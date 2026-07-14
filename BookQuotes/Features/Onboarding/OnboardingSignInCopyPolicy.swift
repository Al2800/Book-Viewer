import Foundation

struct OnboardingSignInCopyPolicy: Equatable {
    let subscriptionsEnabled: Bool
    let cloudSyncEnabled: Bool

    static var current: OnboardingSignInCopyPolicy {
        OnboardingSignInCopyPolicy(
            subscriptionsEnabled: AppReleaseConfiguration.subscriptionsEnabled,
            cloudSyncEnabled: AppReleaseConfiguration.cloudSyncEnabled
        )
    }

    var description: String {
        if subscriptionsEnabled {
            return "Sign in for a free trial and remote AI features. You can continue locally and sign in later."
        }

        if cloudSyncEnabled {
            return "Sign in to sync your library across devices. You can continue locally and sign in later."
        }

        return "Your library works on this device without an account. Sign in later for remote AI features."
    }
}
