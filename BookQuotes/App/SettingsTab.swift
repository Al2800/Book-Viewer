import SwiftUI
import SwiftData

/// Settings tab - configuration, account, and marking definitions
struct SettingsTab: View {
    // MARK: - Environment

    @Environment(AuthService.self) private var authService

    // MARK: - State

    @State private var router = RouterPath()
    @State private var subscriptionService: SubscriptionService?

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            NavigationStack(path: $router.path) {
                SettingsView()
                    .navigationDestination(for: SettingsDestination.self) { destination in
                        switch destination {
                        case .account:
                            if let subscriptionService {
                                AccountView(
                                    authService: authService,
                                    subscriptionService: subscriptionService
                                )
                            }
                        case .markings:
                            MarkingDefinitionsView()
                        case .storage:
                            StorageBackupView()
                        case .aiProcessing:
                            if let subscriptionService {
                                AIProcessingSettingsView(
                                    authService: authService,
                                    subscriptionService: subscriptionService
                                )
                            }
                        case .about:
                            AboutView()
                        }
                    }
            }
        }
        .environment(router)
        .onAppear {
            if subscriptionService == nil {
                subscriptionService = SubscriptionService(authService: authService)
            }
        }
    }
}

/// Navigation destinations for settings
enum SettingsDestination: Hashable {
    case account
    case markings
    case storage
    case aiProcessing
    case about
}

/// Main settings view
struct SettingsView: View {
    @Environment(RouterPath.self) private var router
    @Query private var quotes: [Quote]
    @State private var presentedSheet: SettingsPresentedSheet?

    // MARK: - App Storage

    @AppStorage("libraryViewMode") private var libraryViewMode: String = "grid"
    @AppStorage("autoProcessQueue") private var autoProcessQueue = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage(ProductExperience.v2StorageKey) private var productExperienceV2Enabled = ProductExperience.defaultEnabled

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                SectionCard(title: "Account") {
                    NavigationLink(value: SettingsDestination.account) {
                        SettingsRow(
                            icon: "person.crop.circle",
                            title: AppReleaseConfiguration.subscriptionsEnabled ? "Account & Subscription" : "Account"
                        )
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.accountRow)
                }

                SectionCard(title: "Capture") {
                    NavigationLink(value: SettingsDestination.markings) {
                        SettingsRow(
                            icon: "highlighter",
                            title: "Marking Definitions",
                            subtitle: "Customize underline, highlight, notes"
                        )
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.markingDefinitionsRow)

                    SettingsToggleRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Auto-process Queue",
                        subtitle: "Process captures when online",
                        isOn: $autoProcessQueue
                    )

                    NavigationLink(value: SettingsDestination.aiProcessing) {
                        SettingsRow(
                            icon: "sparkles",
                            title: "Remote AI Processing",
                            subtitle: "Subscription, access, and image-sharing consent"
                        )
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.remoteAIProcessingRow)
                }

                SectionCard(title: "Display") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SettingsRow(
                            icon: "square.grid.2x2",
                            title: "Library View"
                        )

                        Picker(selection: $libraryViewMode) {
                            Text("Grid").tag("grid")
                            Text("List").tag("list")
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.segmented)
                    }

                    SettingsToggleRow(
                        icon: "hand.tap",
                        title: "Haptic Feedback",
                        isOn: $hapticFeedbackEnabled
                    )

                    SettingsToggleRow(
                        icon: "rectangle.split.3x1",
                        title: "Reading, Capture & Explore",
                        subtitle: "Use the new three-tab layout. Turn off to restore Library, Studio and Settings tabs.",
                        isOn: $productExperienceV2Enabled
                    )
                }

                SectionCard(title: "Data") {
                    Button {
                        presentedSheet = .export
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Quotes",
                            subtitle: "Markdown, text, JSON, and more"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.exportQuotesButton)

                    NavigationLink(value: SettingsDestination.storage) {
                        SettingsRow(
                            icon: "externaldrive",
                            title: "Storage & Export"
                        )
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.storageAndExportRow)
                }

                SectionCard(title: "About") {
                    NavigationLink(value: SettingsDestination.about) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About BookQuotes"
                        )
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.aboutRow)

                    Button {
                        presentedSheet = .legalDocument(.privacyPolicy)
                    } label: {
                        SettingsRow(
                            icon: "hand.raised",
                            title: "Privacy Policy",
                            trailingIcon: "doc.text.magnifyingglass"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.privacyPolicyButton)

                    Button {
                        presentedSheet = .legalDocument(.termsOfService)
                    } label: {
                        SettingsRow(
                            icon: "doc.text",
                            title: "Terms of Service",
                            trailingIcon: "doc.text.magnifyingglass"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.termsOfServiceButton)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Settings")
        .background(Color.backgroundPrimary)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .export:
                ExportView(book: nil)
            case let .legalDocument(document):
                LegalDocumentView(document: document)
            }
        }
    }
}

struct AIProcessingSettingsView: View {
    let authService: AuthService
    let subscriptionService: SubscriptionService

    @AppStorage(AIProcessingConsentStore.consentVersionKey) private var consentVersion = ""
    @State private var showingConsent = false
    @State private var showingSignIn = false
    @State private var showingPaywall = false
    @State private var offerConsentAfterPurchase = false

    private var hasCurrentConsent: Bool {
        consentVersion == AIProcessingConsentStore.currentVersion
    }

    private var canEnableRemoteAI: Bool {
        authService.isAuthenticated
            && (subscriptionService.hasActiveSubscription || TestFlightAIBypassPolicy.isActive())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                accessSection

                SectionCard(title: "Remote AI Processing") {
                    SettingsToggleRow(
                        icon: "sparkles",
                        title: "Allow Remote AI Processing",
                        subtitle: "Send marked-page images to the approved quote model",
                        isOn: consentBinding
                    )
                    .disabled(!canEnableRemoteAI)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.remoteAIProcessingToggle)
                }

                SectionCard(title: "Your Choice") {
                    Text(hasCurrentConsent
                         ? "Remote AI is the default for marked-page extraction. You can turn it off at any time; OCR will then run on your device."
                         : "Remote processing is off. Quote capture will use on-device OCR, and books can still be added by ISBN or manual entry.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .navigationTitle("AI Processing")
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $showingConsent) {
            AIProcessingConsentView { _ in
                showingConsent = false
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingSignIn, onDismiss: refreshSubscriptionAccess) {
            SignInView(authService: authService)
        }
        .sheet(isPresented: $showingPaywall, onDismiss: finishSubscriptionActivation) {
            PaywallView(subscriptionService: subscriptionService)
        }
        .task {
            await subscriptionService.loadProducts()
        }
    }

    @ViewBuilder
    private var accessSection: some View {
        SectionCard(title: "Access") {
            if !authService.isAuthenticated {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Sign in required", systemImage: "person.crop.circle.badge.exclamationmark")
                        .font(.headline)
                    Text("Sign in with Apple so a subscription can be verified before a page is sent for remote extraction.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Button("Sign in with Apple") {
                        showingSignIn = true
                    }
                    .buttonStyle(.primary)
                }
            } else if TestFlightAIBypassPolicy.isActive(),
                      !subscriptionService.hasActiveSubscription {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("TestFlight AI testing enabled", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(Color.success)
                    Text("Temporary tester access is active. Subscription purchase and restore still require a separate check before release.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            } else if !subscriptionService.hasActiveSubscription {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Subscription required", systemImage: "sparkles")
                        .font(.headline)
                    Text("Choose a plan or restore an existing purchase to use AI-first quote extraction.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)

                    if subscriptionService.products.isEmpty,
                       let message = subscriptionService.lastError?.localizedDescription {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(Color.warning)
                    }

                    HStack {
                        Button("View Plans") {
                            offerConsentAfterPurchase = true
                            showingPaywall = true
                        }
                        .buttonStyle(.primary)

                        Button("Retry") {
                            refreshSubscriptionAccess()
                        }
                        .buttonStyle(.secondaryCompact)
                    }
                }
            } else {
                Label("Subscription active", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Color.success)
            }
        }
    }

    private var consentBinding: Binding<Bool> {
        Binding(
            get: { hasCurrentConsent },
            set: { wantsRemoteProcessing in
                if wantsRemoteProcessing {
                    if canEnableRemoteAI {
                        showingConsent = true
                    }
                } else {
                    AIProcessingConsentStore.shared.revoke()
                }
            }
        )
    }

    private func refreshSubscriptionAccess() {
        Task {
            await subscriptionService.loadProducts()
        }
    }

    private func finishSubscriptionActivation() {
        Task {
            await subscriptionService.updateSubscriptionStatus()
            guard offerConsentAfterPurchase,
                  subscriptionService.hasActiveSubscription else { return }
            offerConsentAfterPurchase = false
            showingConsent = true
        }
    }
}

struct AIProcessingConsentView: View {
    let onDecision: (Bool) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Color.brand)

                    Text("Remote AI Processing")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.textPrimary)

                    Text("BookQuotes can use remote AI as the primary way to identify marked quotes. This is optional.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)

                    disclosureSection(
                        title: "What is shared",
                        text: "The image you choose to process, the extraction instructions, and the resulting text are sent over TLS to the BookQuotes service and then to the applicable AI provider."
                    )

                    disclosureSection(
                        title: "Who processes it",
                        text: "Hugging Face Inference processes marked-page extraction. The provider receives only the content needed for that request."
                    )

                    disclosureSection(
                        title: "Your alternatives",
                        text: "You can use on-device OCR for quote pages, scan books by ISBN, or add books and quotes manually. You can change this choice at any time in Settings."
                    )

                    Button("Allow Remote AI Processing") {
                        AIProcessingConsentStore.shared.grant()
                        onDecision(true)
                    }
                    .buttonStyle(.primary)

                    Button("Use On-Device Only") {
                        AIProcessingConsentStore.shared.revoke()
                        onDecision(false)
                    }
                    .buttonStyle(.secondary)
                }
                .padding(Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.backgroundPrimary)
        }
    }

    private func disclosureSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum SettingsPresentedSheet: Identifiable {
    case export
    case legalDocument(LegalDocument)

    var id: String {
        switch self {
        case .export:
            return "export"
        case let .legalDocument(document):
            return "legal-\(document.id)"
        }
    }
}

#Preview {
    Group {
        if let container = ModelContainer.preview {
            SettingsTab()
                .environment(AuthService())
                .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
