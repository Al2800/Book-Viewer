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
                            AIProcessingSettingsView()
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
                            subtitle: "Manage image-sharing permission"
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
    @AppStorage(AIProcessingConsentStore.consentVersionKey) private var consentVersion = ""
    @State private var showingConsent = false

    private var hasCurrentConsent: Bool {
        consentVersion == AIProcessingConsentStore.currentVersion
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                SectionCard(title: "Remote AI Processing") {
                    SettingsToggleRow(
                        icon: "sparkles",
                        title: "Allow Remote AI Processing",
                        subtitle: "Send page and cover images to approved providers",
                        isOn: consentBinding
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.remoteAIProcessingToggle)
                }

                SectionCard(title: "Your Choice") {
                    Text(hasCurrentConsent
                         ? "Remote processing is enabled. You can turn it off at any time; page and cover images will then stay on your device for on-device OCR or manual entry."
                         : "Remote processing is off. You can still capture quotes with on-device OCR and add books or quotes manually.")
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
    }

    private var consentBinding: Binding<Bool> {
        Binding(
            get: { hasCurrentConsent },
            set: { wantsRemoteProcessing in
                if wantsRemoteProcessing {
                    showingConsent = true
                } else {
                    AIProcessingConsentStore.shared.revoke()
                }
            }
        )
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

                    Text("BookQuotes can use remote AI to help identify marked quotes and read book covers. This is optional.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)

                    disclosureSection(
                        title: "What is shared",
                        text: "The image you choose to process, the extraction instructions, and the resulting text are sent over TLS to the BookQuotes service and then to the applicable AI provider."
                    )

                    disclosureSection(
                        title: "Who processes it",
                        text: "Hugging Face Inference processes quote-page extraction and Google Gemini processes cover extraction. The provider receives only the content needed for that request."
                    )

                    disclosureSection(
                        title: "Your alternatives",
                        text: "You can use on-device OCR for quote pages, or add books and quotes manually. You can change this choice at any time in Settings."
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
