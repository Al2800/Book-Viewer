import SwiftUI
import SwiftData

/// Settings tab - configuration, account, and marking definitions
struct SettingsTab: View {
    @State private var router = RouterPath()

    var body: some View {
        NavigationStack(path: $router.path) {
            SettingsView()
                .navigationDestination(for: SettingsDestination.self) { destination in
                    switch destination {
                    case .account:
                        AccountView()
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
    var body: some View {
        List {
            Section {
                ContentUnavailableView {
                    Label("Sign In Required", systemImage: "person.crop.circle.badge.questionmark")
                } description: {
                    Text("Sign in with Apple to sync your library across devices.")
                } actions: {
                    Button("Sign in with Apple") {
                        // Apple Sign-In will be implemented
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Subscription") {
                Text("Subscribe to unlock unlimited quote captures and cloud sync.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
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
    SettingsTab()
        .modelContainer(.preview)
}
