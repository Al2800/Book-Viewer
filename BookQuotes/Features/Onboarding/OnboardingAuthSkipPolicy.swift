import Foundation

struct OnboardingAuthSkipPolicy: Equatable {
    let isSimulator: Bool
    let isUITesting: Bool
    let shouldSkipAuthArgument: Bool

    static var current: OnboardingAuthSkipPolicy {
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif

        return OnboardingAuthSkipPolicy(
            isSimulator: isSimulator,
            isUITesting: UITestConfiguration.isUITesting,
            shouldSkipAuthArgument: UITestConfiguration.shouldSkipAuth
        )
    }

    var allowsManualSkip: Bool {
        true
    }

    var shouldAutoSkipAuth: Bool {
        false
    }
}
