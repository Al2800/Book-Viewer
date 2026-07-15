import SwiftUI

struct OnboardingScrollableStep<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct OnboardingWelcomeCarouselView: View {
    let onSkip: () -> Void
    let onComplete: () -> Void

    @State private var carouselState = OnboardingWelcomeCarouselState(
        pageCount: WelcomePage.allCases.count
    )

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if carouselState.showsSkipButton {
                    Button("Skip", action: onSkip)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            TabView(selection: currentPageSelection) {
                ForEach(WelcomePage.allCases) { page in
                    WelcomePageView(page: page)
                        .tag(page.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: Spacing.sm) {
                ForEach(0..<WelcomePage.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index == carouselState.currentPage ? Color.brand : Color.textTertiary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, Spacing.lg)

            Button {
                if carouselState.isLastPage {
                    _ = carouselState.advance()
                    onComplete()
                } else {
                    withAnimation {
                        _ = carouselState.advance()
                    }
                }
            } label: {
                Text(carouselState.primaryButtonTitle)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }

    private var currentPageSelection: Binding<Int> {
        Binding(
            get: { carouselState.currentPage },
            set: { carouselState.currentPage = $0 }
        )
    }
}

struct OnboardingSignInStepView: View {
    let authService: AuthService
    let allowAuthSkip: Bool
    let shouldAutoSkipAuth: Bool
    var copyPolicy: OnboardingSignInCopyPolicy = .current
    @Binding var presentedLegalDocument: LegalDocument?
    let onSignedIn: (User) -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingScrollableStep {
            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.lg)
                header
                Spacer(minLength: Spacing.lg)

                AppleSignInButton(authService: authService) { user in
                    onSignedIn(user)
                    onContinue()
                }
                .padding(.horizontal, Spacing.lg)

                if allowAuthSkip {
                    Button("Continue Without an Account", action: onContinue)
                        .foregroundStyle(Color.textSecondary)
                }

                terms
                    .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear {
            guard shouldAutoSkipAuth else { return }
            onContinue()
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                .font(.system(size: 60))
                .foregroundStyle(Color.brand)

            Text("Sign In or Continue Locally")
                .font(.system(.title, design: .serif).weight(.semibold))

            Text(copyPolicy.description)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
    }

    private var terms: some View {
        VStack(spacing: Spacing.xs) {
            Text("By continuing, you agree to our")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.xs) {
                LegalLinksRow(
                    presentedDocument: $presentedLegalDocument,
                    compactLabels: true
                )
            }
            .font(.caption)
        }
    }
}

struct OnboardingSubscriptionStepView: View {
    let subscriptionService: SubscriptionService
    let onContinue: () -> Void

    var body: some View {
        OnboardingScrollableStep {
            VStack(spacing: Spacing.xl) {
                HStack {
                    Text("Choose Your Plan")
                        .font(.system(.title2, design: .serif).weight(.semibold))
                    Spacer()
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)

                PaywallEmbeddedView(
                    subscriptionService: subscriptionService,
                    onContinue: onContinue
                )
            }
        }
    }
}

struct OnboardingMarkingSetupStepView: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingScrollableStep {
            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.lg)
                header

                MarkingTemplateSelector()
                    .padding(.horizontal, Spacing.lg)

                Spacer(minLength: Spacing.lg)

                Button(action: onContinue) {
                    Text("Continue")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.lg)

                Button("Use defaults", action: onContinue)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.bottom, Spacing.xl)
            }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "highlighter")
                .font(.system(size: 60))
                .foregroundStyle(Color.brand)

            Text("How Do You Mark Books?")
                .font(.system(.title, design: .serif).weight(.semibold))

            Text("Select the marking styles you use most often")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct OnboardingCompletionStepView: View {
    let isCompleting: Bool
    let onStartCapturing: () -> Void

    var body: some View {
        OnboardingScrollableStep {
            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.lg)
                successMessage
                Spacer(minLength: Spacing.lg)

                Button(action: onStartCapturing) {
                    HStack {
                        Text("Start Capturing")
                        Image(systemName: "camera.fill")
                    }
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
                .disabled(isCompleting)
            }
        }
    }

    private var successMessage: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.success)
                .transition(.scale.combined(with: .opacity))

            Text("You're All Set!")
                .font(.system(.title, design: .serif).weight(.semibold))

            Text("Start capturing quotes from your favorite books")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
