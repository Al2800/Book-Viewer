import SwiftUI

/// Initial view showing capture options.
struct CaptureModeSelectionView: View {
    let drafts: [CaptureSession]
    let onResumeDraft: (CaptureSession) -> Void
    let onDeleteDraft: (CaptureSession) -> Void
    let onSelectCoverCapture: () -> Void
    let onSelectQuoteCapture: () -> Void
    let onSelectBatchCapture: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if !drafts.isEmpty {
                    SectionCard(title: "Saved Drafts") {
                        ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                            SavedCaptureDraftRow(
                                session: draft,
                                onResume: { onResumeDraft(draft) },
                                onDelete: { onDeleteDraft(draft) }
                            )

                            if index < drafts.count - 1 {
                                Divider()
                                    .overlay(Color.quoteBorder)
                            }
                        }
                    }
                }

                SectionCard(title: "Choose Capture Mode") {
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

private struct SavedCaptureDraftRow: View {
    let session: CaptureSession
    let onResume: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: onResume) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundStyle(Color.brand)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(session.book?.title ?? "Untitled Book")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)

                        Text("\(session.totalPages) page\(session.totalPages == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("capture_resume_draft_\(session.id.uuidString)")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Delete draft for \(session.book?.title ?? "book")")
        }
        .padding(.vertical, Spacing.sm)
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
        drafts: [],
        onResumeDraft: { _ in },
        onDeleteDraft: { _ in },
        onSelectCoverCapture: {},
        onSelectQuoteCapture: {},
        onSelectBatchCapture: {}
    )
}
