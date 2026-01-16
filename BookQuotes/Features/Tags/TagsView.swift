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

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tags")
                .searchable(text: $searchText, prompt: "Search tags")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showCreateSheet) {
                    TagEditorSheet(mode: .create)
                }
                .sheet(item: $tagToEdit) { tag in
                    TagEditorSheet(mode: .edit(tag))
                }
                .confirmationDialog(
                    "Delete Tag?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    deleteConfirmationActions
                } message: {
                    if let tag = tagToDelete {
                        Text("This will remove the tag from all \(tag.quoteCount) quote\(tag.quoteCount == 1 ? "" : "s"). This cannot be undone.")
                    }
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
        tags.reduce(0) { $0 + $1.quoteCount }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "tag",
            title: "No Tags Yet",
            message: "Tags help you categorize and find quotes quickly. Create tags like 'inspiration', 'productivity', or any label that works for you.",
            action: ("Create Tag", { showCreateSheet = true })
        )
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
        }
    }

    // MARK: - Delete Confirmation

    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button("Delete Tag", role: .destructive) {
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
        if searchText.isEmpty {
            return tags
        }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Actions

    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        try? modelContext.save()
        tagToDelete = nil
    }
}

// MARK: - TagRow

/// Row displaying a tag with edit and delete actions.
private struct TagRow: View {

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
                Text(tag.name)
                    .font(.subheadline)

                Text("\(tag.quoteCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(tagColor.opacity(0.15))
            .foregroundStyle(tagColor)
            .clipShape(Capsule())
        }
    }

    private var tagColor: Color {
        CollectionColor(rawValue: tag.colorName)?.color ?? .blue
    }
}

// MARK: - TagEditorSheet

/// Sheet for creating or editing a tag.
struct TagEditorSheet: View {

    enum Mode {
        case create
        case edit(Tag)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var colorName = "blue"

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("Enter tag name", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Color") {
                    colorPicker
                }
            }
            .navigationTitle(isCreateMode ? "New Tag" : "Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreateMode ? "Create" : "Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let tag) = mode {
                    name = tag.name
                    colorName = tag.colorName
                }
            }
        }
    }

    // MARK: - Color Picker

    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
            ForEach(CollectionColor.allCases) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)
                    .overlay {
                        if colorName == color.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        colorName = color.rawValue
                    }
            }
        }
    }

    // MARK: - Helpers

    private var isCreateMode: Bool {
        if case .create = mode { return true }
        return false
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces).lowercased()

        switch mode {
        case .create:
            let tag = Tag(name: trimmedName, colorName: colorName)
            modelContext.insert(tag)
        case .edit(let tag):
            tag.name = trimmedName
            tag.colorName = colorName
        }

        try? modelContext.save()
        dismiss()
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
                                TagChip(tag: tag) {
                                    removeTag(tag)
                                }
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
        let currentTagIds = Set(quote.tags.map { $0.id })
        return allTags.filter { !currentTagIds.contains($0.id) }
    }

    // MARK: - Actions

    private func addTag(_ tag: Tag) {
        quote.tags.append(tag)
        tag.quotes.append(quote)
        quote.dateModified = Date()
        try? modelContext.save()
    }

    private func removeTag(_ tag: Tag) {
        if let index = quote.tags.firstIndex(where: { $0.id == tag.id }) {
            quote.tags.remove(at: index)
        }
        if let index = tag.quotes.firstIndex(where: { $0.id == quote.id }) {
            tag.quotes.remove(at: index)
        }
        quote.dateModified = Date()
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview("Tags View") {
    TagsView()
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
