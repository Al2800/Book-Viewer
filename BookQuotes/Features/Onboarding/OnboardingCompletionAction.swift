import Foundation

struct OnboardingCompletionAction {
    private let completionStore: OnboardingCompletionStore

    init(completionStore: OnboardingCompletionStore = OnboardingCompletionStore()) {
        self.completionStore = completionStore
    }

    func complete(sessionState: inout OnboardingSessionState) {
        sessionState.complete()
        completionStore.markCompleted()
    }
}
