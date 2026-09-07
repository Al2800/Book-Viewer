import SwiftUI

enum ExtractionReviewPageHeader {
    static func title(orderIndex: Int) -> String {
        "PAGE \(orderIndex + 1)"
    }
}

struct ExtractionReviewPageGroupHeader: View {
    let page: PageCapture
    let onViewPage: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "doc.text")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.gildedAccent)
                .accessibilityHidden(true)
            Text(ExtractionReviewPageHeader.title(orderIndex: page.orderIndex))
                .sectionHeaderStyle()

            Spacer()

            Button {
                HapticManager.light()
                onViewPage()
            } label: {
                Text("View page")
                    .font(.uiPill)
                    .foregroundStyle(Color.actionForeground)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.viewPageButton(orderIndex: page.orderIndex))
        }
    }
}

struct ExtractionReviewAddPassageRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.gildedAccent)
                Text("Add a passage manually")
                    .font(.uiLabel)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color.warmVellum)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
            )
            .elevation(.xs)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.addManualPassage)
    }
}

struct ExtractionReviewPassagesToolbar: ToolbarContent {
    let bookTitle: String
    let passageCount: Int
    let canSave: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: onCancel)
                .foregroundStyle(Color.actionForeground)
                .disabled(isSaving)
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.passagesCancelButton)
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("Passages")
                    .font(.serifHeadline)
                Text(bookTitle)
                    .font(.authorNameSmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Passages, \(bookTitle)")
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(action: onSave) {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .accessibilityLabel("Saving passages")
                    } else {
                        Text("Save \(passageCount)")
                    }
                }

            }
            .buttonStyle(.primaryCompact)
            .disabled(!canSave)
            .accessibilityLabel(isSaving ? "Saving passages" : "Save \(passageCount) \(passageCount == 1 ? "passage" : "passages")")
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.saveToLibraryButton)
        }
    }
}
