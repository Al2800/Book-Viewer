import SwiftUI

// MARK: - Onboarding View

/// Complete onboarding flow for new users.
/// Guides through value proposition, sign-in, and subscription setup.
struct OnboardingView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Services

    let authService: AuthService
    let subscriptionService: SubscriptionService
    private let completionAction: OnboardingCompletionAction
    private let authSkipPolicy: OnboardingAuthSkipPolicy

    // MARK: - State

    @State private var sessionState: OnboardingSessionState
    @State private var presentedLegalDocument: LegalDocument?

    // MARK: - Callbacks

    var onComplete: (() -> Void)?

    init(
        authService: AuthService,
        subscriptionService: SubscriptionService,
        onComplete: (() -> Void)? = nil,
        flowPolicy: OnboardingFlowPolicy = .current,
        completionStore: OnboardingCompletionStore = OnboardingCompletionStore(),
        authSkipPolicy: OnboardingAuthSkipPolicy = .current
    ) {
        self.authService = authService
        self.subscriptionService = subscriptionService
        self.onComplete = onComplete
        self.completionAction = OnboardingCompletionAction(completionStore: completionStore)
        self.authSkipPolicy = authSkipPolicy
        _sessionState = State(initialValue: OnboardingSessionState(flowPolicy: flowPolicy))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.brand.opacity(0.1), Color.backgroundPrimary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack {
                switch sessionState.currentStep {
                case .welcome:
                    OnboardingWelcomeCarouselView(
                        onSkip: advanceFromWelcome,
                        onComplete: advanceFromWelcome
                    )

                case .signIn:
                    OnboardingSignInStepView(
                        authService: authService,
                        allowAuthSkip: authSkipPolicy.allowsManualSkip,
                        shouldAutoSkipAuth: authSkipPolicy.shouldAutoSkipAuth,
                        presentedLegalDocument: $presentedLegalDocument,
                        onSignedIn: { sessionState.signedIn($0) },
                        onContinue: advanceFromSignIn
                    )

                case .subscription:
                    OnboardingSubscriptionStepView(
                        subscriptionService: subscriptionService,
                        onContinue: advanceFromSubscription
                    )

                case .markingSetup:
                    OnboardingMarkingSetupStepView(
                        onContinue: advanceFromMarkingSetup
                    )

                case .aiConsent:
                    AIProcessingConsentView { _ in
                        advanceFromAIConsent()
                    }

                case .complete:
                    OnboardingCompletionStepView(
                        isCompleting: sessionState.isCompleting,
                        onStartCapturing: completeOnboarding
                    )
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sessionState.currentStep)
        .sheet(item: $presentedLegalDocument) { document in
            LegalDocumentView(document: document)
        }
    }

    private func advanceFromSignIn() {
        withAnimation {
            sessionState.advanceFromSignIn()
        }
    }

    // MARK: - Actions

    private func advanceFromWelcome() {
        withAnimation {
            sessionState.advanceFromWelcome()
        }
    }

    private func advanceFromSubscription() {
        withAnimation {
            sessionState.advanceFromSubscription()
        }
    }

    private func advanceFromMarkingSetup() {
        withAnimation {
            sessionState.advanceFromMarkingSetup()
        }
    }

    private func advanceFromAIConsent() {
        withAnimation {
            sessionState.advanceFromAIConsent()
        }
    }

    private func completeOnboarding() {
        completionAction.complete(sessionState: &sessionState)

        HapticManager.success()

        onComplete?()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Onboarding View") {
    let authService = AuthService()
    return OnboardingView(
        authService: authService,
        subscriptionService: SubscriptionService(authService: authService)
    )
}

#Preview("Welcome Page") {
    WelcomePageView(page: .capture)
}
