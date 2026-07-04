import SwiftUI
import SwiftData

// MARK: - CollectionCard

/// Card component displaying a collection with icon, name, and quote count.
struct CollectionCard: View {

    // MARK: - Properties

    let collection: Collection

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon
            iconView

            // Name and count
            VStack(spacing: Spacing.xs) {
                Text(collection.name)
                    .font(.bookTitle)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(quoteCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .elevation(.sm)
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(collectionColor.opacity(0.15))
                .frame(width: 60, height: 60)

            Image(systemName: collection.icon)
                .font(.title2)
                .foregroundStyle(collectionColor)
        }
    }

    // MARK: - Helpers

    private var collectionColor: Color {
        CollectionColor.named(collection.colorName).color
    }

    private var quoteCountText: String {
        let count = collection.quoteCount
        if count == 0 {
            return "No quotes"
        } else if count == 1 {
            return "1 quote"
        } else {
            return "\(count) quotes"
        }
    }
}

// MARK: - CollectionRow

/// Compact row variant for displaying a collection in a list.
struct CollectionRow: View {

    // MARK: - Properties

    let collection: Collection

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(collectionColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: collection.icon)
                    .font(.body)
                    .foregroundStyle(collectionColor)
            }

            // Name and description
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(collection.name)
                    .font(.bookTitleSmall)
                    .foregroundStyle(.primary)

                if let description = collection.collectionDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(quoteCountText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Quote count badge
            Text("\(collection.quoteCount)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.backgroundSecondary)
                .clipShape(Capsule())
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Helpers

    private var collectionColor: Color {
        CollectionColor.named(collection.colorName).color
    }

    private var quoteCountText: String {
        let count = collection.quoteCount
        if count == 0 {
            return "Empty"
        } else if count == 1 {
            return "1 quote"
        } else {
            return "\(count) quotes"
        }
    }
}

// MARK: - CollectionChip

/// Small chip for showing collection membership on a quote.
struct CollectionChip: View {

    // MARK: - Properties

    let collection: Collection
    var showRemoveButton: Bool = false
    var onRemove: (() -> Void)?

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: collection.icon)
                .font(.caption2)

            Text(collection.name)
                .font(.caption)
                .lineLimit(1)

            if showRemoveButton {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(collectionColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(collectionColor.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private var collectionColor: Color {
        CollectionColor.named(collection.colorName).color
    }
}

// MARK: - Preview

#Preview("Collection Card") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
        ForEach(0..<4) { index in
            let colors = ["ink", "forest", "plum", "mustard"]
            let icons = ["star.fill", "heart.fill", "bookmark.fill", "lightbulb"]
            let names = ["Favorites", "Inspiration", "To Read", "Ideas"]

            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(CollectionColor.named(colors[index]).color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: icons[index])
                        .font(.title2)
                        .foregroundStyle(CollectionColor.named(colors[index]).color)
                }

                VStack(spacing: Spacing.xs) {
                    Text(names[index])
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(index * 5 + 3) quotes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.lg)
            .background(Color.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .elevation(.sm)
        }
    }
    .padding()
}

#Preview("Collection Row") {
    List {
        ForEach(0..<3) { index in
            let colors = ["ink", "forest", "plum"]
            let icons = ["star.fill", "heart.fill", "bookmark.fill"]
            let names = ["Favorites", "Inspiration", "To Read"]

            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(CollectionColor.named(colors[index]).color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icons[index])
                        .font(.body)
                        .foregroundStyle(CollectionColor.named(colors[index]).color)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(names[index])
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("\(index * 5 + 3) quotes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(index * 5 + 3)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.backgroundSecondary)
                    .clipShape(Capsule())
            }
            .padding(.vertical, Spacing.xs)
        }
    }
}

#Preview("Collection Chips") {
    HStack(spacing: 8) {
        ForEach(0..<3) { index in
            let colors = ["ink", "forest", "plum"]
            let icons = ["star.fill", "heart.fill", "bookmark.fill"]
            let names = ["Favorites", "Inspiration", "Reading"]

            HStack(spacing: Spacing.xs) {
                Image(systemName: icons[index])
                    .font(.caption2)

                Text(names[index])
                    .font(.caption)
            }
            .foregroundStyle(CollectionColor.named(colors[index]).color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(CollectionColor.named(colors[index]).color.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    .padding()
}
