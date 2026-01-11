import SwiftUI
import Combine

/// Main app view with tab-based navigation
struct ContentView: View {
    @State private var selectedTab: Tab = .library
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NetworkMonitor.self) private var networkMonitor

    /// Queue stats for badge display
    @State private var queueStats = QueueStats()
    @State private var statsCancellable: AnyCancellable?

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryTab()
                .tabItem {
                    Label(Tab.library.title, systemImage: Tab.library.systemImage)
                }
                .tag(Tab.library)
                .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.libraryTab)

            CaptureTab()
                .tabItem {
                    Label(Tab.capture.title, systemImage: Tab.capture.systemImage)
                }
                .tag(Tab.capture)
                .badge(queueBadgeCount)
                .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.captureTab)

            SettingsTab()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
                .accessibilityIdentifier(AccessibilityIdentifiers.Tabs.settingsTab)
        }
        .onAppear {
            subscribeToQueueStats()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: networkMonitor.isConnected) { wasConnected, isConnected in
            handleConnectivityChange(wasConnected: wasConnected, isConnected: isConnected)
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

    /// Handle app lifecycle changes
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App came to foreground - resume queue processing
            Task {
                if let queueManager = CaptureQueueManager.shared {
                    await queueManager.start()
                }
            }

        case .background:
            // App going to background - stop queue processing
            Task {
                CaptureQueueManager.shared?.stop()
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
