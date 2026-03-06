import SwiftUI
import StoreKit

// MARK: - Onboarding View

/// Complete onboarding flow for new users.
/// Guides through value proposition, sign-in, and subscription setup.
struct OnboardingView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Services

    let authService: AuthService
    let subscriptionService: SubscriptionService

    // MARK: - State

    @State private var currentStep: OnboardingStep = UITestConfiguration.shouldOpenSubscriptionMediaScreen ? .subscription : .welcome
    @State private var currentPage = 0
    @State private var signedInUser: User?
    @State private var isCompleting = false
    @State private var presentedLegalDocument: LegalDocument?

    // MARK: - Callbacks

    var onComplete: (() -> Void)?

    // MARK: - Simulator Auth Skips

    private var allowAuthSkip: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return UITestConfiguration.shouldSkipAuth
        #endif
    }

    private var shouldAutoSkipAuth: Bool {
        #if targetEnvironment(simulator)
        return !UITestConfiguration.isUITesting
        #else
        return false
        #endif
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
                switch currentStep {
                case .welcome:
                    welcomeCarousel

                case .signIn:
                    signInStep

                case .subscription:
                    subscriptionStep

                case .markingSetup:
                    markingSetupStep

                case .complete:
                    completionStep
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
        .sheet(item: $presentedLegalDocument) { document in
            LegalDocumentView(document: document)
        }
    }

    // MARK: - Welcome Carousel

    private var welcomeCarousel: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                if currentPage < WelcomePage.allCases.count - 1 {
                    Button("Skip") {
                        withAnimation {
                            currentStep = .signIn
                        }
                    }
                    .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)

            // Page carousel
            TabView(selection: $currentPage) {
                ForEach(WelcomePage.allCases) { page in
                    WelcomePageView(page: page)
                        .tag(page.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicators
            HStack(spacing: Spacing.sm) {
                ForEach(0..<WelcomePage.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.brand : Color.textTertiary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, Spacing.lg)

            // Continue button
            Button {
                if currentPage < WelcomePage.allCases.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    withAnimation {
                        currentStep = .signIn
                    }
                }
            } label: {
                Text(currentPage < WelcomePage.allCases.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Sign-In Step

    private var signInStep: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Header
            VStack(spacing: Spacing.md) {
                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.brand)

                Text("Create Your Account")
                    .font(.title)
                    .fontWeight(.bold)

                Text(
                    AppReleaseConfiguration.subscriptionsEnabled
                        ? "Sign in to start your 7-day free trial and unlock AI extraction while keeping your library stored on this device"
                        : AppReleaseConfiguration.cloudSyncEnabled
                            ? "Sign in to sync your library across devices and unlock all features"
                            : "Sign in to enable AI extraction while keeping your library stored on this device"
                )
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer()

            // Sign-in button
            AppleSignInButton(authService: authService) { user in
                signedInUser = user
                advanceFromSignIn()
            }
            .padding(.horizontal, Spacing.lg)

            if allowAuthSkip {
                Button("Maybe later") {
                    advanceFromSignIn()
                }
                .foregroundStyle(Color.textSecondary)
            }

            // Terms
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
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            guard shouldAutoSkipAuth else { return }
            advanceFromSignIn()
        }
    }

    // MARK: - Subscription Step

    private var subscriptionStep: some View {
        VStack(spacing: Spacing.xl) {
            // Header
            HStack {
                Text("Choose Your Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)

            // Embedded paywall
            PaywallEmbeddedView(subscriptionService: subscriptionService) {
                withAnimation {
                    currentStep = .markingSetup
                }
            }
        }
    }

    private func advanceFromSignIn() {
        withAnimation {
            currentStep = AppReleaseConfiguration.subscriptionsEnabled ? .subscription : .markingSetup
        }
    }

    // MARK: - Marking Setup Step

    private var markingSetupStep: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Header
            VStack(spacing: Spacing.md) {
                Image(systemName: "highlighter")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.brand)

                Text("How Do You Mark Books?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Select the marking styles you use most often")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Marking style options
            MarkingTemplateSelector()
                .padding(.horizontal, Spacing.lg)

            Spacer()

            // Continue button
            Button {
                withAnimation {
                    currentStep = .complete
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .padding(.horizontal, Spacing.lg)

            // Skip option
            Button("Use defaults") {
                withAnimation {
                    currentStep = .complete
                }
            }
            .foregroundStyle(Color.textSecondary)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Completion Step

    private var completionStep: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Success animation
            VStack(spacing: Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.success)
                    .transition(.scale.combined(with: .opacity))

                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Start capturing quotes from your favorite books")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Start button
            Button {
                completeOnboarding()
            } label: {
                HStack {
                    Text("Start Capturing")
                    Image(systemName: "camera.fill")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .disabled(isCompleting)
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        isCompleting = true

        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Enable first-capture coaching
        UserDefaults.standard.set(true, forKey: "showFirstCaptureCoaching")

        HapticManager.success()

        onComplete?()
        dismiss()
    }
}

// MARK: - Onboarding Step

extension OnboardingView {
    enum OnboardingStep {
        case welcome
        case signIn
        case subscription
        case markingSetup
        case complete
    }
}

// MARK: - Welcome Page

enum WelcomePage: Int, CaseIterable, Identifiable {
    case capture
    case organize
    case discover

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .capture: return "camera.viewfinder"
        case .organize: return "books.vertical"
        case .discover: return "sparkles"
        }
    }

    var title: String {
        switch self {
        case .capture: return "Capture Quotes Instantly"
        case .organize: return "Build Your Library"
        case .discover: return "Rediscover Wisdom"
        }
    }

    var description: String {
        switch self {
        case .capture:
            return "Point your camera at any marked page. Our AI extracts underlines, highlights, and margin notes automatically."
        case .organize:
            return "Organize quotes by book, topic, or custom collections. Your library stays available on this device, with exports ready whenever you want a backup."
        case .discover:
            return "Search your entire library instantly. Surface forgotten insights and share your favorite passages."
        }
    }
}

// MARK: - Welcome Page View

private struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(Color.brand)

            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Marking Template Selector

private struct MarkingTemplateSelector: View {
    @State private var selectedStyles: Set<MarkingType> = [.underline, .highlight]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(MarkingType.allCases, id: \.self) { type in
                MarkingStyleOption(
                    type: type,
                    isSelected: selectedStyles.contains(type)
                ) {
                    if selectedStyles.contains(type) {
                        selectedStyles.remove(type)
                    } else {
                        selectedStyles.insert(type)
                    }
                    HapticManager.light()
                }
            }
        }
    }
}

// MARK: - Marking Style Option

private struct MarkingStyleOption: View {
    let type: MarkingType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: type.systemImage)
                    .font(.title2)

                Text(type.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? Color.brand.opacity(0.1) : Color.backgroundSecondary)
            .foregroundStyle(isSelected ? Color.brand : Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Embedded Paywall View

/// Simplified paywall for embedding in onboarding.
private struct PaywallEmbeddedView: View {
    let subscriptionService: SubscriptionService
    let onContinue: () -> Void

    @State private var selectedProduct: Product?
    @State private var selectedMediaPlan: MediaSubscriptionPlan = .yearly
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Trial banner
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundStyle(Color.brand)
                Text(selectedProduct?.freeTrialDescription ?? "Start with a 7-day free trial")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color.brand.opacity(0.1))
            .clipShape(Capsule())

            // Plan options
            Group {
                if subscriptionService.isLoading {
                    ProgressView()
                        .padding(.vertical, Spacing.xl)
                } else if shouldShowMediaPlans {
                    VStack(spacing: Spacing.md) {
                        ForEach(MediaSubscriptionPlan.allCases) { plan in
                            MediaSubscriptionOptionCard(
                                plan: plan,
                                isSelected: selectedMediaPlan == plan
                            ) {
                                selectedMediaPlan = plan
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                } else if subscriptionService.products.isEmpty {
                    Text("Unable to load subscription options right now.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                } else {
                    VStack(spacing: Spacing.md) {
                        ForEach(subscriptionService.products) { product in
                            SubscriptionOptionCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                monthlyProduct: subscriptionService.monthlyProduct
                            ) {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }

            Spacer()

            // Subscribe button
            Button {
                startTrial()
            } label: {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Free Trial")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.brand)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, Spacing.lg)
            .disabled(isProcessing || (!shouldShowMediaPlans && selectedProduct == nil))

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            // Skip option
            Button("Maybe later") {
                onContinue()
            }
            .foregroundStyle(Color.textSecondary)
            .padding(.bottom, Spacing.lg)
        }
        .task {
            if subscriptionService.products.isEmpty {
                await subscriptionService.loadProducts()
            }
            selectedProduct = subscriptionService.yearlyProduct ?? subscriptionService.monthlyProduct
        }
    }

    private var shouldShowMediaPlans: Bool {
        UITestConfiguration.shouldOpenSubscriptionMediaScreen && subscriptionService.products.isEmpty
    }

    private func startTrial() {
        if shouldShowMediaPlans {
            onContinue()
            return
        }

        guard let selectedProduct else { return }
        isProcessing = true
        errorMessage = nil

        Task {
            defer { isProcessing = false }

            do {
                let transaction = try await subscriptionService.purchase(selectedProduct)
                if transaction != nil || subscriptionService.hasActiveSubscription {
                    onContinue()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private enum MediaSubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .monthly:
            return "$4.99"
        case .yearly:
            return "$39.99"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly:
            return "Flexible access for regular readers"
        case .yearly:
            return "Best value for committed readers"
        }
    }

    var period: String {
        switch self {
        case .monthly:
            return "per month"
        case .yearly:
            return "per year"
        }
    }

    var badge: String? {
        switch self {
        case .monthly:
            return nil
        case .yearly:
            return "Best Value"
        }
    }
}

private struct MediaSubscriptionOptionCard: View {
    let plan: MediaSubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.brand : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.brand)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.brand, in: Capsule())
                        }
                    }

                    Text("7-day free trial for eligible new subscribers")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(plan.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text(plan.price)
                        .font(.headline)

                    Text(plan.period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? Color.brand.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(
                        isSelected ? Color.brand : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
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
