import SwiftUI
import SwiftData

/// Settings tab - configuration, account, and marking definitions
struct SettingsTab: View {
    // MARK: - Properties

    let authService: AuthService
    let subscriptionService: SubscriptionService

    // MARK: - State

    @State private var router = RouterPath()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $router.path) {
            SettingsView()
                .navigationDestination(for: SettingsDestination.self) { destination in
                    switch destination {
                    case .account:
                        AccountView(
                            authService: authService,
                            subscriptionService: subscriptionService
                        )
                    case .markings:
                        MarkingDefinitionsView()
                    case .storage:
                        StorageBackupView()
                    case .about:
                        AboutView()
                    }
                }
        }
        .environment(router)
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
    @State private var showExportSheet = false

    // MARK: - App Storage

    @AppStorage("libraryViewMode") private var libraryViewMode: String = "grid"
    @AppStorage("autoProcessQueue") private var autoProcessQueue = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    var body: some View {
        List {
            Section("Account") {
                NavigationLink(value: SettingsDestination.account) {
                    Label("Account & Subscription", systemImage: "person.circle")
                }
            }

            Section("Capture") {
                NavigationLink(value: SettingsDestination.markings) {
                    Label("Marking Definitions", systemImage: "highlighter")
                }

                Toggle(isOn: $autoProcessQueue) {
                    Label("Auto-process Queue", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Display") {
                Picker(selection: $libraryViewMode) {
                    Text("Grid").tag("grid")
                    Text("List").tag("list")
                } label: {
                    Label("Library View", systemImage: "square.grid.2x2")
                }

                Toggle(isOn: $hapticFeedbackEnabled) {
                    Label("Haptic Feedback", systemImage: "hand.tap")
                }
            }

            Section("Data") {
                Button {
                    showExportSheet = true
                } label: {
                    Label("Export Quotes", systemImage: "square.and.arrow.up")
                }

                NavigationLink(value: SettingsDestination.storage) {
                    Label("Storage & Backup", systemImage: "externaldrive")
                }
            }

            Section("About") {
                NavigationLink(value: SettingsDestination.about) {
                    Label("About BookQuotes", systemImage: "info.circle")
                }

                Link(destination: URL(string: "https://bookquotes.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(destination: URL(string: "https://bookquotes.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showExportSheet) {
            ExportView(quotes: quotes)
        }
    }
}

// MARK: - Settings Destination Views

/// Account and subscription management
struct AccountView: View {
    // MARK: - Properties

    let authService: AuthService
    let subscriptionService: SubscriptionService

    // MARK: - State

    @State private var showSignIn = false
    @State private var showPaywall = false
    @State private var showSignOutConfirmation = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        List {
            // Account section
            if authService.isAuthenticated {
                accountSection
            } else {
                signInPromptSection
            }

            // Subscription section
            subscriptionSection

            // Actions section
            actionsSection
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSignIn) {
            SignInView(authService: authService)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptionService: subscriptionService)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your data will remain on this device.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .task {
            await subscriptionService.loadProducts()
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                // Avatar
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.brand)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    if let user = authService.currentUser {
                        Text(user.displayNameOrEmail)
                            .font(.headline)

                        if let email = user.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Subscription badge
                SubscriptionBadge(subscriptionService: subscriptionService)
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var signInPromptSection: some View {
        Section {
            VStack(spacing: Spacing.md) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                Text("Sign In Required")
                    .font(.headline)

                Text("Sign in with Apple to sync your library across devices and access your subscription.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showSignIn = true
                } label: {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
            }
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section("Subscription") {
            if subscriptionService.hasActiveSubscription {
                // Active subscription info
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text(subscriptionTitle)
                            .font(.headline)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }

                    if subscriptionService.isInTrial {
                        Label("Free Trial Active", systemImage: "gift.fill")
                            .font(.subheadline)
                            .foregroundStyle(.brand)
                    }

                    if let status = subscriptionService.subscriptionStatus,
                       let renewalDate = status.renewalInfo?.currentPeriodEndDate {
                        Text("Renews \(renewalDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xs)

                // Manage subscription
                Button {
                    Task {
                        await subscriptionService.manageSubscription()
                    }
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
            } else {
                // No subscription - show upgrade prompt
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Unlock Premium")
                        .font(.headline)

                    Text("Get unlimited quote captures, cloud sync, and more.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showPaywall = true
                    } label: {
                        Text("View Plans")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    private var subscriptionTitle: String {
        if let product = subscriptionService.purchasedSubscription {
            if product.id.contains("yearly") {
                return "BookQuotes Yearly"
            } else if product.id.contains("monthly") {
                return "BookQuotes Monthly"
            }
            return product.displayName
        }
        return "BookQuotes Premium"
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            // Restore purchases
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                HStack {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")

                    if isRestoring {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isRestoring)

            // Sign out (only if signed in)
            if authService.isAuthenticated {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }

    // MARK: - Actions

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await subscriptionService.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func signOut() {
        Task {
            await authService.signOut()
        }
    }
}

// MARK: - AccountView Preview

#Preview("Account - Signed Out") {
    NavigationStack {
        AccountView(
            authService: AuthService(),
            subscriptionService: SubscriptionService(authService: AuthService())
        )
    }
}

/// Marking definitions management
struct MarkingDefinitionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MarkingDefinition.sortOrder) private var definitions: [MarkingDefinition]

    var body: some View {
        List {
            Section {
                Text("Define what different markings in your books mean. These will help the AI understand your annotations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Your Markings") {
                if definitions.isEmpty {
                    ContentUnavailableView {
                        Label("No Definitions", systemImage: "highlighter")
                    } description: {
                        Text("Add marking definitions to personalize quote extraction.")
                    }
                } else {
                    ForEach(definitions) { definition in
                        MarkingDefinitionRow(definition: definition)
                    }
                }
            }
        }
        .navigationTitle("Marking Definitions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Add new definition
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            seedDefaultsIfNeeded()
        }
    }

    private func seedDefaultsIfNeeded() {
        MarkingDefinition.seedDefaults(in: modelContext)
    }
}

/// Row for a marking definition
struct MarkingDefinitionRow: View {
    let definition: MarkingDefinition

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: definition.icon)
                .font(.title3)
                .foregroundStyle(colorForName(definition.colorName))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(definition.name)
                    .font(.headline)

                Text(definition.meaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if definition.isSystemDefault {
                Text("System")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.backgroundSecondary)
                    .clipShape(Capsule())
            }
        }
        .opacity(definition.isEnabled ? 1 : 0.5)
    }

    private func colorForName(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "teal": return .teal
        case "gray", "grey": return .gray
        default: return .blue
        }
    }
}

/// About screen
struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "books.vertical.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.brand)

                    Text("BookQuotes")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Capture the wisdom in your books")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }

            Section("Version") {
                LabeledContent("App Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            }

            Section("Credits") {
                Text("Built with SwiftUI, SwiftData, and Gemini AI")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Storage and backup management
struct StorageBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var quotes: [Quote]

    @State private var showExportOptions = false
    @State private var isExporting = false

    var body: some View {
        List {
            // Storage stats
            Section("Storage Usage") {
                LabeledContent("Books", value: "\(books.count)")
                LabeledContent("Quotes", value: "\(quotes.count)")
                LabeledContent("Images", value: estimatedImageStorage)
            }

            // Backup options
            Section("Backup") {
                Button {
                    showExportOptions = true
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }

                Text("Export your entire library as a backup file that can be restored later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Data management
            Section("Data Management") {
                Button(role: .destructive) {
                    // Show clear cache confirmation
                } label: {
                    Label("Clear Image Cache", systemImage: "trash")
                }

                Text("Clear cached images to free up storage space. Original images in your library will not be affected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Storage & Backup")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Export Options", isPresented: $showExportOptions) {
            Button("Export as JSON") {
                exportAsJSON()
            }
            Button("Export as Markdown") {
                exportAsMarkdown()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var estimatedImageStorage: String {
        let imageCount = books.filter { $0.coverThumbnailData != nil }.count +
                         quotes.filter { $0.sourceImageThumbnailData != nil }.count
        // Rough estimate: ~50KB per thumbnail
        let estimatedMB = Double(imageCount) * 0.05
        if estimatedMB < 1 {
            return "< 1 MB"
        }
        return String(format: "%.1f MB", estimatedMB)
    }

    private func exportAsJSON() {
        // TODO: Implement JSON export
    }

    private func exportAsMarkdown() {
        // TODO: Implement Markdown export
    }
}

#Preview {
    let authService = AuthService()
    return SettingsTab(
        authService: authService,
        subscriptionService: SubscriptionService(authService: authService)
    )
    .modelContainer(.preview)
}
