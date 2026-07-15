import SwiftUI
import SwiftData

// MARK: - TagsView

/// View showing all tags in a flow layout with management options.
struct TagsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \Tag.name) private var tags: [Tag]

    // MARK: - State

    @State private var showCreateSheet = false
    @State private var searchText = ""
    @State private var tagToEdit: Tag?
    @State private var tagToDelete: Tag?
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    /// Pushed onto the Library tab's navigation stack.
    var body: some View {
        content
            .background(Color.backgroundPrimary)
            .navigationTitle("Tags")
            .searchable(text: $searchText, prompt: "Search tags")
            .accessibilityIdentifier(AccessibilityIdentifiers.Tags.listView)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showCreateSheet) {
                TagEditorSheet(mode: .create)
            }
            .sheet(item: $tagToEdit) { tag in
                TagEditorSheet(mode: .edit(tag))
            }
            .confirmationDialog(
                deletePrompt.title,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteConfirmationActions
            } message: {
                if let tag = tagToDelete {
                    Text(TagDeletionPrompt(quoteCount: tag.quoteCount).message)
                }
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if tags.isEmpty {
            emptyState
        } else {
            tagsList
        }
    }

    // MARK: - Tags List

    private var tagsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Stats
                statsHeader

                // Tags flow
                FlowLayout(spacing: Spacing.sm) {
                    ForEach(filteredTags) { tag in
                        TagRow(
                            tag: tag,
                            onEdit: { tagToEdit = tag },
                            onDelete: {
                                tagToDelete = tag
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: Spacing.lg) {
            StatBadge(
                label: "Tags",
                value: "\(tags.count)",
                icon: "tag"
            )

            StatBadge(
                label: "Total Uses",
                value: "\(totalUses)",
                icon: "number"
            )
        }
    }

    private var totalUses: Int {
        tagsPresentation.totalUses
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "tag",
            title: "No Tags Yet",
            message: "Tags help you categorize and find quotes quickly. Create tags like 'inspiration', 'productivity', or any label that works for you.",
            action: ("Create Tag", { showCreateSheet = true })
        )
        .accessibilityIdentifier(AccessibilityIdentifiers.Tags.emptyState)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Create Tag")
            .accessibilityIdentifier(AccessibilityIdentifiers.Tags.addButton)
        }
    }

    // MARK: - Delete Confirmation

    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button(deletePrompt.destructiveActionTitle, role: .destructive) {
            if let tag = tagToDelete {
                deleteTag(tag)
            }
        }
        Button("Cancel", role: .cancel) {
            tagToDelete = nil
        }
    }

    // MARK: - Computed

    private var filteredTags: [Tag] {
        tagsPresentation.filteredTags(searchText: searchText)
    }

    private var tagsPresentation: TagsPresentation {
        TagsPresentation(tags: tags)
    }

    private var deletePrompt: TagDeletionPrompt {
        TagDeletionPrompt(quoteCount: tagToDelete?.quoteCount ?? 0)
    }

    // MARK: - Actions

    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        try? modelContext.save()
        tagToDelete = nil
    }
}

// MARK: - AddTagToQuoteSheet

/// Sheet for adding tags to a quote.
struct AddTagToQuoteSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \Tag.name) private var allTags: [Tag]

    // MARK: - Properties

    @Bindable var quote: Quote

    // MARK: - State

    @State private var selectedTagIds: Set<UUID> = []
    @State private var newTagName = ""
    @State private var showCreateSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Current tags
                if !quote.tags.isEmpty {
                    Section("Current Tags") {
                        FlowLayout(spacing: Spacing.sm) {
                            ForEach(quote.tags) { tag in
                                TagChip(tag: tag, onRemove: {
                                    removeTag(tag)
                                })
                            }
                        }
                    }
                }

                // Available tags
                if !availableTags.isEmpty {
                    Section("Available Tags") {
                        ForEach(availableTags) { tag in
                            Button {
                                addTag(tag)
                            } label: {
                                HStack {
                                    TagChip(tag: tag)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Create new
                Section {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label("Create New Tag", systemImage: "tag.fill")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                TagEditorSheet(mode: .create)
            }
        }
    }

    // MARK: - Computed

    private var availableTags: [Tag] {
        AddTagToQuotePresentation(
            allTags: allTags,
            currentTags: quote.tags
        ).availableTags
    }

    // MARK: - Actions

    private func addTag(_ tag: Tag) {
        QuoteTagMutation().add(tag, to: quote)
        try? modelContext.save()
    }

    private func removeTag(_ tag: Tag) {
        QuoteTagMutation().remove(tag, from: quote)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview("Tags View") {
    NavigationStack {
        TagsView()
    }
    .modelContainer(for: Tag.self, inMemory: true)
}

#Preview("Tag Editor") {
    TagEditorSheet(mode: .create)
        .modelContainer(for: Tag.self, inMemory: true)
}

#Preview("Add Tag to Quote") {
    AddTagToQuoteSheet(quote: Quote(text: "Sample quote"))
        .modelContainer(for: [Tag.self, Quote.self], inMemory: true)
}
