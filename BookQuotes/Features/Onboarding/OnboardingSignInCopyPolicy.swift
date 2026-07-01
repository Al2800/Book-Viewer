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
            return "Sign in to start your 7-day free trial and unlock AI extraction while keeping your library stored on this device"
        }

        if cloudSyncEnabled {
            return "Sign in to sync your library across devices and unlock all features"
        }

        return "Sign in to enable AI extraction while keeping your library stored on this device"
    }
}
