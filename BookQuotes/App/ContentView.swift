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
                LibraryTab()
                    .tabItem {
                        Label(Tab.library.title, systemImage: Tab.library.systemImage)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.libraryTab)
                    }
                    .tag(Tab.library)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.libraryTab)

                CaptureTab(onBookCreated: { _ in
                    selectedTab = .library
                })
                    .tabItem {
                        Label(Tab.capture.title, systemImage: Tab.capture.systemImage)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.captureTab)
                    }
                    .tag(Tab.capture)
                    .badge(queueBadgeCount)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.captureTab)

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
                    .opacity(0.01)
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

        // If we're intentionally starting empty for a given UI test run, ensure the wipe happens
        // even if `uiTestSeeded` is already set from a prior install/run.
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

        // `uiTestSeeded` lives in UserDefaults and can survive situations where the SwiftData store
        // is empty (for example: data reset, model container recovery, or app re-install oddities).
        // If the DB is empty, allow re-seeding.
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
        showPersistenceBanner = true

        // Auto-dismiss after a short period unless the user dismisses sooner.
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            guard showPersistenceBanner else { return }
            showPersistenceBanner = false
            persistenceRecoveryMessage = ""
        }
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
            // App came to foreground - resume queue processing
            Task {
                if let subscriptionService {
                    await subscriptionService.updateSubscriptionStatus()
                }
                if let queueManager = CaptureQueueManager.shared {
                    await queueManager.start()
                }
            }

        case .background:
            // App going to background - stop queue processing
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
            // Just came online - resume queue processing
            Task {
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
