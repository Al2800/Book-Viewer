import SwiftUI
import SwiftData

// MARK: - OrganizationFilterBar

/// Horizontal scrolling bar for filtering by collections and tags.
struct OrganizationFilterBar: View {

    // MARK: - Queries

    @Query(sort: \Collection.sortOrder) private var collections: [Collection]
    @Query(sort: \Tag.name) private var tags: [Tag]

    // MARK: - Bindings

    @Binding var selectedCollectionIds: Set<UUID>
    @Binding var selectedTagIds: Set<UUID>

    // MARK: - Body

    var body: some View {
        if !collections.isEmpty || !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    // Collections
                    collectionsSection

                    // Divider if both exist
                    if !collections.isEmpty && !tags.isEmpty {
                        divider
                    }

                    // Tags
                    tagsSection

                    // Clear all if any selected
                    clearAllButton
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.xs)
            .background(Color.backgroundSecondary.opacity(0.3))
        }
    }

    // MARK: - Collections Section

    @ViewBuilder
    private var collectionsSection: some View {
        ForEach(collections) { collection in
            CollectionFilterChip(
                collection: collection,
                isSelected: selectedCollectionIds.contains(collection.id)
            ) {
                toggleCollection(collection.id)
            }
        }
    }

    // MARK: - Tags Section

    @ViewBuilder
    private var tagsSection: some View {
        ForEach(tags) { tag in
            TagFilterChip(
                tag: tag,
                isSelected: selectedTagIds.contains(tag.id)
            ) {
                toggleTag(tag.id)
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 1, height: 20)
            .padding(.horizontal, Spacing.xs)
    }

    // MARK: - Clear All Button

    @ViewBuilder
    private var clearAllButton: some View {
        if !selectedCollectionIds.isEmpty || !selectedTagIds.isEmpty {
            Button {
                withAnimation {
                    selectedCollectionIds.removeAll()
                    selectedTagIds.removeAll()
                }
            } label: {
                Text("Clear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, Spacing.xs)
        }
    }

    // MARK: - Actions

    private func toggleCollection(_ id: UUID) {
        withAnimation {
            if selectedCollectionIds.contains(id) {
                _ = selectedCollectionIds.remove(id)
            } else {
                selectedCollectionIds.insert(id)
            }
        }
    }

    private func toggleTag(_ id: UUID) {
        withAnimation {
            if selectedTagIds.contains(id) {
                _ = selectedTagIds.remove(id)
            } else {
                selectedTagIds.insert(id)
            }
        }
    }
}

// MARK: - CollectionFilterChip

/// Filter chip for a collection.
struct CollectionFilterChip: View {

    let collection: Collection
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: collection.icon)
                    .font(.caption2)

                Text(collection.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? collectionColor : collectionColor.opacity(0.15))
            .foregroundStyle(isSelected ? .white : collectionColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var collectionColor: Color {
        CollectionColor(rawValue: collection.colorName)?.color ?? .blue
    }
}

// MARK: - TagFilterChip

/// Filter chip for a tag.
struct TagFilterChip: View {

    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "tag")
                    .font(.caption2)

                Text(tag.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? tagColor : tagColor.opacity(0.15))
            .foregroundStyle(isSelected ? .white : tagColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var tagColor: Color {
        CollectionColor(rawValue: tag.colorName)?.color ?? .blue
    }
}

// MARK: - Active Organization Filters Bar

/// Bar showing currently active collection and tag filters as dismissable pills.
struct ActiveOrganizationFiltersBar: View {

    // MARK: - Queries

    @Query private var collections: [Collection]
    @Query private var tags: [Tag]

    // MARK: - Bindings

    @Binding var selectedCollectionIds: Set<UUID>
    @Binding var selectedTagIds: Set<UUID>

    // MARK: - Body

    var body: some View {
        if !selectedCollectionIds.isEmpty || !selectedTagIds.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    // Collection pills
                    ForEach(Array(selectedCollectionIds), id: \.self) { id in
                        if let collection = collections.first(where: { $0.id == id }) {
                            FilterPill(
                                label: collection.name,
                                icon: collection.icon,
                                color: CollectionColor(rawValue: collection.colorName)?.color ?? .blue
                            ) {
                                withAnimation {
                                    _ = selectedCollectionIds.remove(id)
                                }
                            }
                        }
                    }

                    // Tag pills
                    ForEach(Array(selectedTagIds), id: \.self) { id in
                        if let tag = tags.first(where: { $0.id == id }) {
                            FilterPill(
                                label: tag.name,
                                icon: "tag",
                                color: CollectionColor(rawValue: tag.colorName)?.color ?? .blue
                            ) {
                                withAnimation {
                                    _ = selectedTagIds.remove(id)
                                }
                            }
                        }
                    }

                    // Clear all
                    Button {
                        withAnimation {
                            selectedCollectionIds.removeAll()
                            selectedTagIds.removeAll()
                        }
                    } label: {
                        Text("Clear All")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.xs)
            .background(barBackground)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var barBackground: Color {
        Color.backgroundSecondary.opacity(0.5)
    }
}

// MARK: - Organization Filter Extensions

extension Array where Element == Quote {
    /// Filter quotes by collections and tags.
    func filtered(
        byCollectionIds collectionIds: Set<UUID>,
        tagIds: Set<UUID>
    ) -> [Quote] {
        filter { quote in
            // Collection filter (OR logic)
            if !collectionIds.isEmpty {
                let quoteCollectionIds = Set(quote.collections.map { $0.id })
                if quoteCollectionIds.isDisjoint(with: collectionIds) {
                    return false
                }
            }

            // Tag filter (OR logic)
            if !tagIds.isEmpty {
                let quoteTagIds = Set(quote.tags.map { $0.id })
                if quoteTagIds.isDisjoint(with: tagIds) {
                    return false
                }
            }

            return true
        }
    }
}

extension Array where Element == Book {
    /// Filter books by collections and tags (based on their quotes).
    func filtered(
        byCollectionIds collectionIds: Set<UUID>,
        tagIds: Set<UUID>
    ) -> [Book] {
        filter { book in
            // Collection filter (OR logic)
            if !collectionIds.isEmpty {
                let bookCollectionIds = Set(book.quotes.flatMap { $0.collections }.map { $0.id })
                if bookCollectionIds.isDisjoint(with: collectionIds) {
                    return false
                }
            }

            // Tag filter (OR logic)
            if !tagIds.isEmpty {
                let bookTagIds = Set(book.quotes.flatMap { $0.tags }.map { $0.id })
                if bookTagIds.isDisjoint(with: tagIds) {
                    return false
                }
            }

            return true
        }
    }
}

// MARK: - Preview

#Preview("Organization Filter Bar") {
    @Previewable @State var selectedCollections: Set<UUID> = []
    @Previewable @State var selectedTags: Set<UUID> = []

    VStack(spacing: 20) {
        OrganizationFilterBar(
            selectedCollectionIds: $selectedCollections,
            selectedTagIds: $selectedTags
        )

        Text("Selected Collections: \(selectedCollections.count)")
        Text("Selected Tags: \(selectedTags.count)")

        Spacer()
    }
    .modelContainer(for: [Collection.self, Tag.self], inMemory: true)
}

#Preview("Active Filters") {
    @Previewable @State var selectedCollections: Set<UUID> = []
    @Previewable @State var selectedTags: Set<UUID> = []

    VStack(spacing: 20) {
        ActiveOrganizationFiltersBar(
            selectedCollectionIds: $selectedCollections,
            selectedTagIds: $selectedTags
        )

        Spacer()
    }
    .modelContainer(for: [Collection.self, Tag.self], inMemory: true)
}
