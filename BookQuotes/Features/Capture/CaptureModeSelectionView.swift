import SwiftUI

/// Initial view showing capture options.
struct CaptureModeSelectionView: View {
    let onSelectCoverCapture: () -> Void
    let onSelectQuoteCapture: () -> Void
    let onSelectBatchCapture: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                CaptureSectionCard(title: "Choose Capture Mode") {
                    ForEach(CaptureModeOption.all) { option in
                        CaptureModeRow(option: option, action: action(for: option.kind))

                        if option.id != CaptureModeOption.all.last?.id {
                            Divider()
                                .overlay(Color.quoteBorder)
                        }
                    }
                }

                Label("Even light, page filling the frame.", systemImage: "lightbulb")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Spacing.sm)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.large)
    }

    private func action(for kind: CaptureModeOption.Kind) -> () -> Void {
        switch kind {
        case .cover:
            return onSelectCoverCapture
        case .quote:
            return onSelectQuoteCapture
        case .batch:
            return onSelectBatchCapture
        }
    }
}

struct CaptureSectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .sectionHeaderStyle()

            VStack(spacing: Spacing.sm) {
                content
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct CaptureModeRow: View {
    let option: CaptureModeOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(option.accent.color.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: option.systemImage)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(option.accent.color)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(option.title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(option.accessibilityId)
    }
}

#Preview("Mode Selection") {
    CaptureModeSelectionView(
        onSelectCoverCapture: {},
        onSelectQuoteCapture: {},
        onSelectBatchCapture: {}
    )
}
