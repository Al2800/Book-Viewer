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
                    .foregroundStyle(Color.brand)
                    .frame(minHeight: 44)
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
    let hasAppeared: Bool
    let canSave: Bool
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", action: onCancel)
                .foregroundStyle(Color.brand)
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
            .opacity(hasAppeared ? 1 : 0)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(action: onSave) {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(Color.darkLinen)
                    } else {
                        Text("Save to Library")
                            .font(.uiPill.weight(.semibold))
                            .foregroundStyle(Color.darkLinen)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: 36)
                .background(LinearGradient.foilAccent, in: Capsule())
                .opacity(canSave ? 1 : 0.4)
            }
            .disabled(!canSave)
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.saveToLibraryButton)
        }
    }
}
