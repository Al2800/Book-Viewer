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
                SettingsSectionCard(title: "Account") {
                    NavigationLink(value: SettingsDestination.account) {
                        SettingsRow(
                            icon: "person.crop.circle",
                            title: AppReleaseConfiguration.subscriptionsEnabled ? "Account & Subscription" : "Account"
                        )
                    }
                }

                SettingsSectionCard(title: "Capture") {
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
                }

                SettingsSectionCard(title: "Display") {
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

                SettingsSectionCard(title: "Data") {
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
                            title: "Storage & Backup"
                        )
                    }
                }

                SettingsSectionCard(title: "About") {
                    NavigationLink(value: SettingsDestination.about) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About BookQuotes"
                        )
                    }

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
