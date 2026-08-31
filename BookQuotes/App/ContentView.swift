import SwiftUI
import Combine
import SwiftData

/// Main app view with tab-based navigation
struct ContentView: View {
    @State private var selectedTab: Tab = .library
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("uiTestSeeded") private var uiTestSeeded = false
    @AppStorage("persistence_recovery_message") private var persistenceRecoveryMessage = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(AuthService.self) private var authService

    @State private var subscriptionService: SubscriptionService?
    @State private var showOnboarding = false
    @State private var isSeedingTestData = false

    @State private var showPersistenceBanner = false
    @State private var pendingLibraryBookToOpen: Book?

    /// Queue stats for badge display
    @State private var queueStats = QueueStats()
    @State private var statsCancellable: AnyCancellable?
    private var shouldAutoCompleteOnboarding: Bool {
        #if targetEnvironment(simulator)
        return !UITestConfiguration.isUITesting
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                LibraryTab(bookToOpen: $pendingLibraryBookToOpen)
                    .tabItem {
                        Label(Tab.library.title, systemImage: Tab.library.systemImage)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.libraryTab)
                    }
                    .tag(Tab.library)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.libraryTab)

                CaptureTab(
                    onBookCreated: openBookInLibrary,
                    onQuotesSaved: openBookInLibrary,
                    onExit: { selectedTab = .library }
                )
                    .tabItem {
                        Label(Tab.capture.title, systemImage: Tab.capture.systemImage)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.captureTab)
                    }
                    .tag(Tab.capture)
                    .badge(queueBadgeCount)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.captureTab)

                StudioTab()
                    .tabItem {
                        Label(Tab.studio.title, systemImage: Tab.studio.systemImage)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.studioTab)
                    }
                    .tag(Tab.studio)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.studioTab)

                SettingsTab()
                    .tabItem {
                        Label(Tab.settings.title, systemImage: Tab.settings.systemImage)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.settingsTab)
                    }
                    .tag(Tab.settings)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.settingsTab)
            }
            .tint(Color.brand)
            .glassTabBar()
            .background(Color.backgroundPrimary.ignoresSafeArea())

            if UITestConfiguration.isUITesting && uiTestSeeded && !UITestConfiguration.isAppStoreMediaMode {
                Text("UI Test Seeded")
                    .font(.caption2)
                    .foregroundStyle(Color.clear)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Common.uiTestSeeded)
            }

            if showPersistenceBanner, !persistenceRecoveryMessage.isEmpty {
                VStack {
                    ErrorBanner(
                        message: persistenceRecoveryMessage,
                        onDismiss: {
                            showPersistenceBanner = false
                            persistenceRecoveryMessage = ""
                        },
                        style: .warning
                    )
                    Spacer()
                }
                .ignoresSafeArea(.container, edges: .top)
            }
        }
        .onAppear {
            subscribeToQueueStats()
            ensureSubscriptionService()
            applyAppStoreMediaOverrides()
            updateOnboardingVisibility()
            presentPersistenceRecoveryIfNeeded()
        }
        .onChange(of: hasCompletedOnboarding) { _, _ in
            updateOnboardingVisibility()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: networkMonitor.isConnected) { wasConnected, isConnected in
            handleConnectivityChange(wasConnected: wasConnected, isConnected: isConnected)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            if let subscriptionService {
                OnboardingView(
                    authService: authService,
                    subscriptionService: subscriptionService
                )
            } else {
                ProgressView()
            }
        }
        .task {
            await seedTestDataIfNeeded()
        }
    }

    private func applyAppStoreMediaOverrides() {
        guard UITestConfiguration.isAppStoreMediaMode else { return }

        let screen = (UITestConfiguration.appStoreMediaScreen ?? "library")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch screen {
        case "onboarding":
            fallthrough
        case "subscription":
            hasCompletedOnboarding = false
            selectedTab = .library

        case "capture":
            hasCompletedOnboarding = true
            selectedTab = .capture

        case "studio":
            hasCompletedOnboarding = true
            selectedTab = .studio

        case "settings":
            hasCompletedOnboarding = true
            selectedTab = .settings

        case "library":
            fallthrough
        default:
            hasCompletedOnboarding = true
            selectedTab = .library
        }
    }

    private func openBookInLibrary(_ book: Book) {
        pendingLibraryBookToOpen = book
        selectedTab = .library
    }

    /// Badge count for the capture tab (pending + failed items)
    private var queueBadgeCount: Int {
        let count = queueStats.pendingCount + queueStats.failedCount
        return count > 0 ? count : 0
    }

    /// Subscribe to queue stats updates
    private func subscribeToQueueStats() {
        guard let queueManager = CaptureQueueManager.shared else { return }

        statsCancellable = queueManager.statsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [self] stats in
                self.queueStats = stats
            }
    }

    /// Ensure subscription service is initialized once.
    private func ensureSubscriptionService() {
        guard subscriptionService == nil else { return }
        let service = SubscriptionService(authService: authService)
        service.startListening()
        subscriptionService = service
    }

    private func seedTestDataIfNeeded() async {
        guard UITestConfiguration.isUITesting, !isSeedingTestData else { return }

        if UITestConfiguration.shouldStartWithEmptyLibrary {
            isSeedingTestData = true
            defer { isSeedingTestData = false }

            let seeder = UITestDataSeeder(modelContext: modelContext)
            do {
                try await seeder.seedTestDataIfNeeded()
                uiTestSeeded = true
            } catch {
                print("UI test empty-library seeding failed: \(error)")
            }
            return
        }

        if uiTestSeeded {
            do {
                let descriptor = FetchDescriptor<Book>()
                let count = try modelContext.fetchCount(descriptor)
                if count > 0 {
                    return
                }
            } catch {
                // If we can't count, fall through and attempt to reseed.
            }

            uiTestSeeded = false
        }

        guard !uiTestSeeded else { return }
        isSeedingTestData = true

        defer { isSeedingTestData = false }

        let seeder = UITestDataSeeder(modelContext: modelContext)
        do {
            try await seeder.seedTestDataIfNeeded()

            if UITestConfiguration.shouldPreloadSearchTestData,
               let searchService = try? SearchService() {
                await seeder.rebuildSearchIndexIfNeeded(searchService: searchService)
            }

            uiTestSeeded = true
        } catch {
            print("UI test seeding failed: \(error)")
        }
    }

    private func presentPersistenceRecoveryIfNeeded() {
        guard !persistenceRecoveryMessage.isEmpty else { return }
        // Persistence recovery represents possible user-data loss. Keep the message visible
        // until the reader explicitly acknowledges it rather than clearing it on a timer.
        showPersistenceBanner = true
    }

    /// Determine whether onboarding should be presented.
    private func updateOnboardingVisibility() {
        if shouldAutoCompleteOnboarding {
            if !hasCompletedOnboarding {
                hasCompletedOnboarding = true
            }
            showOnboarding = false
            return
        }

        showOnboarding = !hasCompletedOnboarding
    }

    /// Handle app lifecycle changes
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task {
                if !authService.isAuthenticated {
                    _ = await authService.restoreSession()
                }
                if let subscriptionService {
                    await subscriptionService.updateSubscriptionStatus()
                }
                if let queueManager = CaptureQueueManager.shared {
                    await queueManager.start()
                }
            }

        case .background:
            Task {
                await CaptureQueueManager.shared?.stop()
            }

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    /// Handle network connectivity changes
    private func handleConnectivityChange(wasConnected: Bool, isConnected: Bool) {
        if !wasConnected && isConnected {
            Task {
                if !authService.isAuthenticated {
                    _ = await authService.restoreSession()
                }
                if let queueManager = CaptureQueueManager.shared {
                    await queueManager.start()
                }
            }
        }
    }
}

#Preview {
    Group {
        if let container = ModelContainer.preview {
            ContentView()
                .modelContainer(container)
                .environment(NetworkMonitor())
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
