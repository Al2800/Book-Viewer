import SwiftUI

/// Row displaying a tag with edit and delete actions.
struct TagRow: View {
    let tag: Tag
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(presentation.name)
                    .font(.subheadline)

                Text(presentation.quoteCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(tagColor.opacity(0.15))
            .foregroundStyle(tagColor)
            .clipShape(Capsule())
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Tags.tagChip)
    }

    private var presentation: TagRowPresentation {
        TagRowPresentation(tag: tag)
    }

    private var tagColor: Color {
        presentation.collectionColor.color
    }
}
