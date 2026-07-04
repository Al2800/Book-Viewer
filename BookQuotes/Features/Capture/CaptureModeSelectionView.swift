import SwiftUI

/// Initial view showing capture options.
struct CaptureModeSelectionView: View {
    let onSelectCoverCapture: () -> Void
    let onSelectQuoteCapture: () -> Void
    let onSelectBatchCapture: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                CaptureSummaryCard()

                CaptureSectionCard(title: "Choose Capture Mode") {
                    ForEach(CaptureModeOption.all) { option in
                        CaptureModeRow(option: option, action: action(for: option.kind))
                    }
                }

                Label("Even light, page filling the frame.", systemImage: "lightbulb")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
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

private struct CaptureSummaryCard: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            CaptureSummaryPill(systemImage: "camera", text: "Camera Ready")
            CaptureSummaryPill(systemImage: "text.viewfinder", text: "Review Before Save")

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct CaptureSummaryPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.backgroundSecondary)
        )
        .overlay {
            Capsule()
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        }
    }
}

private struct CaptureModeRow: View {
    let option: CaptureModeOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                        }

                    Image(systemName: option.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(option.accent.color)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(option.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
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
