import SwiftUI

/// Main app view with tab-based navigation
struct ContentView: View {
    @State private var selectedTab: Tab = .library

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryTab()
                .tabItem {
                    Label(Tab.library.title, systemImage: Tab.library.systemImage)
                }
                .tag(Tab.library)

            CaptureTab()
                .tabItem {
                    Label(Tab.capture.title, systemImage: Tab.capture.systemImage)
                }
                .tag(Tab.capture)

            SettingsTab()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(.preview)
}
