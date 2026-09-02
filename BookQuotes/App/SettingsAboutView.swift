import SwiftUI

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
                        .font(.largeTitle)
                        .foregroundStyle(Color.brand)

                    Text("BookQuotes")
                        .font(.screenTitle)

                    Text("Capture the wisdom in your books")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .paperCard()

                infoCard(title: "Version") {
                    SettingsInfoRow(label: "App Version", value: appVersion)
                    SettingsInfoRow(label: "Build", value: buildNumber)
                }

                infoCard(title: "Credits") {
                    Text("Built with SwiftUI, SwiftData, Apple Vision, and Hugging Face Inference")
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
                .sectionHeaderStyle()

            content()
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}
