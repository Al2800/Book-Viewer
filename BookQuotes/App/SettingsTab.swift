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
    @State private var showExportSheet = false

    // MARK: - App Storage

    @AppStorage("libraryViewMode") private var libraryViewMode: String = "grid"
    @AppStorage("autoProcessQueue") private var autoProcessQueue = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                settingsSectionCard(title: "Account") {
                    NavigationLink(value: SettingsDestination.account) {
                        SettingsRow(
                            icon: "person.crop.circle",
                            title: "Account & Subscription",
                            subtitle: "Manage plan, billing, and sign-in"
                        )
                    }
                }

                settingsSectionCard(title: "Capture") {
                    NavigationLink(value: SettingsDestination.markings) {
                        SettingsRow(
                            icon: "highlighter",
                            title: "Marking Definitions",
                            subtitle: "Customize underline, highlight, notes"
                        )
                    }

                    SettingsToggleRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Auto-process Queue",
                        subtitle: "Process captures when online",
                        isOn: $autoProcessQueue
                    )
                }

                settingsSectionCard(title: "Display") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        SettingsRow(
                            icon: "square.grid.2x2",
                            title: "Library View",
                            subtitle: "Grid or list layout"
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
                        subtitle: "Subtle taps for actions",
                        isOn: $hapticFeedbackEnabled
                    )
                }

                settingsSectionCard(title: "Data") {
                    Button {
                        showExportSheet = true
                    } label: {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Quotes",
                            subtitle: "Markdown, text, JSON, and more"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: SettingsDestination.storage) {
                        SettingsRow(
                            icon: "externaldrive",
                            title: "Storage & Backup",
                            subtitle: "Cloud sync and local storage"
                        )
                    }
                }

                settingsSectionCard(title: "About") {
                    NavigationLink(value: SettingsDestination.about) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About BookQuotes",
                            subtitle: "Version, credits, and support"
                        )
                    }

                    if let privacyURL = URL(string: "https://bookquotes.app/privacy") {
                        Link(destination: privacyURL) {
                            SettingsRow(
                                icon: "hand.raised",
                                title: "Privacy Policy",
                                subtitle: "How your data is handled",
                                trailingIcon: "arrow.up.right"
                            )
                        }
                    }

                    if let termsURL = URL(string: "https://bookquotes.app/terms") {
                        Link(destination: termsURL) {
                            SettingsRow(
                                icon: "doc.text",
                                title: "Terms of Service",
                                subtitle: "Usage terms and policies",
                                trailingIcon: "arrow.up.right"
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Settings")
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $showExportSheet) {
            ExportView(book: nil)
        }
    }
}

private extension SettingsView {
    func settingsSectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: Spacing.sm) {
                content()
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailingIcon: String?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        trailingIcon: String? = "chevron.right"
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailingIcon = trailingIcon
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle()
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(icon: String, title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                        }

                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .toggleStyle(.switch)
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
        .scrollContentBackground(.hidden)
        .background(Color.backgroundPrimary)
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
                    .foregroundStyle(Color.brand)

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
                .accessibilityIdentifier(AccessibilityIdentifiers.Settings.signInButton)
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
                            .foregroundStyle(Color.brand)
                    }

                    Text("Renews automatically")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.restorePurchasesButton)

            // Sign out (only if signed in)
            if authService.isAuthenticated {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Settings.signOutButton)
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

/// About screen
struct AboutView: View {
    /// App version from CFBundleShortVersionString
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    /// Build number from CFBundleVersion
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "books.vertical.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.brand)

                    Text("BookQuotes")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Capture the wisdom in your books")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .paperCard()

                infoCard(title: "Version") {
                    InfoRow(label: "App Version", value: appVersion)
                    InfoRow(label: "Build", value: buildNumber)
                }

                infoCard(title: "Credits") {
                    Text("Built with SwiftUI, SwiftData, and Gemini AI")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundPrimary)
    }

    private func infoCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            content()
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
        }
        .fieldChrome()
    }
}

/// Storage and backup management
struct StorageBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var quotes: [Quote]

    @State private var showExportOptions = false
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var exportFilename: String?
    @State private var showExportResult = false
    @State private var exportError: String?

    // Cache clearing state
    @State private var showClearCacheConfirmation = false
    @State private var isClearingCache = false
    @State private var cacheCleared = false
    @State private var bytesCleared: Int64 = 0

    private let exportService = ExportService()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                storageCard
                backupCard
                cacheCard
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Storage & Backup")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundPrimary)
        .confirmationDialog("Export Options", isPresented: $showExportOptions) {
            Button("Export as JSON") {
                Task { await exportAsJSON() }
            }
            Button("Export as Markdown") {
                Task { await exportAsMarkdown() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Clear Image Cache?",
            isPresented: $showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Cache", role: .destructive) {
                Task { await clearImageCache() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove cached images from completed captures and exports. Your quotes and book covers will not be affected.")
        }
        .alert("Export", isPresented: $showExportResult) {
            if let url = exportURL {
                ShareLink(item: url) {
                    Text("Share")
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let error = exportError {
                Text(error)
            } else if let filename = exportFilename {
                Text("Successfully exported \(filename)")
            }
        }
        .overlay {
            if isExporting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("Exporting...")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
            }
        }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Storage Usage")
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            InfoRow(label: "Books", value: "\(books.count)")
            InfoRow(label: "Quotes", value: "\(quotes.count)")
            InfoRow(label: "Images", value: estimatedImageStorage)
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Backup")
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            Button {
                showExportOptions = true
            } label: {
                Label("Export All Data", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .glassButton()

            Text("Export your entire library as a backup file that can be restored later.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Data Management")
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            Button(role: .destructive) {
                showClearCacheConfirmation = true
            } label: {
                HStack {
                    Label("Clear Image Cache", systemImage: "trash")
                    if isClearingCache {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(isClearingCache)

            if cacheCleared {
                Label(
                    "Cleared \(ByteCountFormatter.string(fromByteCount: bytesCleared, countStyle: .file))",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)
            } else {
                Text("Clear cached images to free up storage space. Original images in your library will not be affected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    private var estimatedImageStorage: String {
        let imageCount = books.filter { $0.coverThumbnailData != nil }.count +
                         quotes.filter { $0.sourceImageData != nil }.count
        // Rough estimate: ~50KB per thumbnail
        let estimatedMB = Double(imageCount) * 0.05
        if estimatedMB < 1 {
            return "< 1 MB"
        }
        return String(format: "%.1f MB", estimatedMB)
    }

    private func exportAsJSON() async {
        await performExport(format: .json)
    }

    private func exportAsMarkdown() async {
        await performExport(format: .markdown)
    }

    private func performExport(format: ExportFormat) async {
        guard !quotes.isEmpty else {
            exportError = "No quotes to export."
            showExportResult = true
            return
        }

        isExporting = true
        defer { isExporting = false }

        // Reset previous state
        exportURL = nil
        exportFilename = nil
        exportError = nil

        do {
            let options = ExportOptions(
                includeMetadata: true,
                groupByBook: true,
                includePageNumbers: true,
                includeMarginNotes: true
            )

            let result = try await exportService.export(
                quotes: quotes,
                format: format,
                options: options
            )

            switch result {
            case let .file(url, filename):
                exportURL = url
                exportFilename = filename
                HapticManager.success()
            case let .apiSuccess(message):
                exportFilename = message
                HapticManager.success()
            case let .apiError(message):
                exportError = message
                HapticManager.error()
            }
        } catch {
            exportError = error.localizedDescription
            HapticManager.error()
        }

        showExportResult = true
    }

    // MARK: - Cache Clearing

    private func clearImageCache() async {
        isClearingCache = true
        cacheCleared = false
        bytesCleared = 0

        defer { isClearingCache = false }

        var totalBytesCleared: Int64 = 0
        let fileManager = FileManager.default

        // 1. Clear completed/cancelled queue items' images
        totalBytesCleared += clearQueueCache(fileManager: fileManager)

        // 2. Clear export temp directory
        totalBytesCleared += clearExportCache(fileManager: fileManager)

        // 3. Clear captures directory (completed sessions)
        totalBytesCleared += clearCapturesDirectory(fileManager: fileManager)

        bytesCleared = totalBytesCleared
        cacheCleared = true
        HapticManager.success()
    }

    private func clearQueueCache(fileManager: FileManager) -> Int64 {
        var bytesCleared: Int64 = 0
        let queueDirectory = CaptureQueueItem.queueDirectory

        guard let enumerator = fileManager.enumerator(
            at: queueDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        // Get IDs of pending/processing items (don't delete their images)
        let activeImagePaths = Set(
            (try? modelContext.fetch(FetchDescriptor<CaptureQueueItem>()))?
                .filter { $0.status == .pending || $0.status == .processing }
                .map { $0.imagePath } ?? []
        )

        for case let fileURL as URL in enumerator {
            // Skip if this image belongs to an active queue item
            if activeImagePaths.contains(fileURL.lastPathComponent) {
                continue
            }

            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                do {
                    try fileManager.removeItem(at: fileURL)
                    bytesCleared += Int64(size)
                } catch {
                    // Continue with other files
                }
            }
        }

        return bytesCleared
    }

    private func clearExportCache(fileManager: FileManager) -> Int64 {
        var bytesCleared: Int64 = 0

        guard let exportDir = try? ExportFileWriter.exportDirectory() else { return 0 }

        guard let enumerator = fileManager.enumerator(
            at: exportDir,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                bytesCleared += Int64(size)
            }
        }

        // Remove the entire export directory
        try? fileManager.removeItem(at: exportDir)

        return bytesCleared
    }

    private func clearCapturesDirectory(fileManager: FileManager) -> Int64 {
        var bytesCleared: Int64 = 0

        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        let capturesDir = documentsURL.appendingPathComponent("captures", isDirectory: true)

        guard fileManager.fileExists(atPath: capturesDir.path) else { return 0 }

        guard let enumerator = fileManager.enumerator(
            at: capturesDir,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               resourceValues.isRegularFile == true,
               let size = resourceValues.fileSize {
                bytesCleared += Int64(size)
            }
        }

        // Remove the entire captures directory
        try? fileManager.removeItem(at: capturesDir)

        return bytesCleared
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
