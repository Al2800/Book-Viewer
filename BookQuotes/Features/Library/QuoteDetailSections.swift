import SwiftUI

struct QuoteDetailOrganizeSection: View {
    let quote: Quote
    let onCollections: () -> Void
    let onTags: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Collections & Tags")
                .sectionHeaderStyle()

            if quote.collections.isEmpty && quote.tags.isEmpty {
                Text("Group this quote into collections or label it with tags.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            if !quote.collections.isEmpty {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(quote.collections) { collection in
                        QuoteCollectionChip(collection: collection)
                    }
                }
            }

            if !quote.tags.isEmpty {
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(quote.tags) { tag in
                        TagChip(tag: tag)
                    }
                }
            }

            HStack(spacing: Spacing.sm) {
                Button(action: onCollections) {
                    Label("Collections", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.secondaryCompact)

                Button(action: onTags) {
                    Label("Tags", systemImage: "tag")
                }
                .buttonStyle(.secondaryCompact)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .paperCard()
    }
}

struct QuoteDetailSourceImageButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Label("View Source Image", systemImage: "photo")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .paperCard(cornerRadius: CornerRadius.md)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.sourceImageButton)
    }
}

struct QuoteDetailBookSection: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("From")
                .sectionHeaderStyle()

            NavigationLink(value: book) {
                BookHeaderView(book: book, style: .compact)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

/// Small capsule showing a collection the quote belongs to.
private struct QuoteCollectionChip: View {
    let collection: Collection

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: collection.icon)
                .font(.caption2)

            Text(collection.name)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(chipColor.opacity(0.15))
        .foregroundStyle(chipColor)
        .clipShape(Capsule())
    }

    private var chipColor: Color {
        CollectionColor.named(collection.colorName).color
    }
}
