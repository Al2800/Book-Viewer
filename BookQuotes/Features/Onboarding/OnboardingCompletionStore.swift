import Foundation

struct OnboardingCompletionStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func markCompleted() {
        userDefaults.set(true, forKey: "hasCompletedOnboarding")
        userDefaults.set(true, forKey: "showFirstCaptureCoaching")
    }
}
