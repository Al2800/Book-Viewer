import SwiftUI
import SwiftData

// MARK: - OrganizationFilterBar

/// Horizontal scrolling bar for filtering by collections and tags.
struct OrganizationFilterBar: View {

    // MARK: - Queries

    @Query(sort: \Collection.sortOrder) private var collections: [Collection]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Bindings

    @Binding var selectedCollectionIds: Set<UUID>
    @Binding var selectedTagIds: Set<UUID>

    // MARK: - Body

    var body: some View {
        if !collections.isEmpty || !tags.isEmpty || activeFilterCount > 0 {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(activeFilterCount == 0 ? "Filter books" : "Filter books · \(activeFilterCount) active")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .accessibilityIdentifier("library_book_filter_scope")
                    Spacer()
                    clearAllButton
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        allPill
                        collectionsSection
                        if !collections.isEmpty && !tags.isEmpty {
                            divider
                        }
                        tagsSection
                    }
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, Spacing.xs)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.organizationFilterBar)
            }
        }
    }

    private var activeFilterCount: Int {
        selectedCollectionIds.count + selectedTagIds.count
    }

    // MARK: - All Pill

    private var allPill: some View {
        let isAllSelected = selectedCollectionIds.isEmpty && selectedTagIds.isEmpty
        return Button {
            HapticManager.selection()
            withAnimation(reduceMotion ? .none : .quickSpring) {
                selectedCollectionIds.removeAll()
                selectedTagIds.removeAll()
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "books.vertical")
                    .font(.caption2)
                Text("All books")
                    .font(.caption.weight(isAllSelected ? .semibold : .regular))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: 44)
            .background(
                Capsule()
                    .fill(isAllSelected ? Color.brand : Color.backgroundSecondary)
            )
            .foregroundStyle(isAllSelected ? .white : Color.textPrimary)
            .overlay(
                Capsule()
                    .stroke(isAllSelected ? Color.clear : Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isAllSelected ? .isSelected : [])
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Collections.collectionRow)
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Tags.tagChip)
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
                withAnimation(reduceMotion ? .none : .quickSpring) {
                    selectedCollectionIds.removeAll()
                    selectedTagIds.removeAll()
                }
            } label: {
                Text("Clear")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear book filters")
            .accessibilityIdentifier("library_clear_book_filters")
        }
    }

    // MARK: - Actions

    private func toggleCollection(_ id: UUID) {
        HapticManager.selection()
        withAnimation(reduceMotion ? .none : .quickSpring) {
            if selectedCollectionIds.contains(id) {
                _ = selectedCollectionIds.remove(id)
            } else {
                selectedCollectionIds.insert(id)
            }
        }
    }

    private func toggleTag(_ id: UUID) {
        HapticManager.selection()
        withAnimation(reduceMotion ? .none : .quickSpring) {
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
            .frame(minHeight: 44)
            .background(isSelected ? collectionColor : collectionColor.opacity(0.15))
            .foregroundStyle(isSelected ? .white : collectionColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var collectionColor: Color {
        CollectionColor.named(collection.colorName).color
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
            .frame(minHeight: 44)
            .background(isSelected ? tagColor : tagColor.opacity(0.15))
            .foregroundStyle(isSelected ? .white : tagColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var tagColor: Color {
        CollectionColor.named(tag.colorName).color
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
                                color: CollectionColor.named(collection.colorName).color
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
                                color: CollectionColor.named(tag.colorName).color
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
