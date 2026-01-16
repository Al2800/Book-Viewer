import SwiftUI
import SwiftData

// MARK: - AddToCollectionSheet

/// Sheet for adding a quote to one or more collections.
/// Shows checkboxes for each collection and allows creating new ones.
struct AddToCollectionSheet: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries

    @Query(sort: \Collection.sortOrder) private var collections: [Collection]

    // MARK: - Properties

    /// The quote to add to collections
    @Bindable var quote: Quote

    // MARK: - State

    @State private var selectedCollectionIds: Set<UUID> = []
    @State private var showCreateSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Collections section
                collectionsSection

                // Create new collection
                createCollectionSection
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                    }
                }
            }
            .onAppear {
                // Pre-select collections quote is already in
                selectedCollectionIds = Set(quote.collections.map { $0.id })
            }
            .sheet(isPresented: $showCreateSheet) {
                CollectionEditorSheet(mode: .create)
            }
        }
    }

    // MARK: - Collections Section

    @ViewBuilder
    private var collectionsSection: some View {
        if collections.isEmpty {
            Section {
                Text("No collections yet")
                    .foregroundStyle(.secondary)
            }
        } else {
            Section {
                ForEach(collections) { collection in
                    CollectionSelectionRow(
                        collection: collection,
                        isSelected: selectedCollectionIds.contains(collection.id)
                    ) {
                        toggleSelection(collection.id)
                    }
                }
            }
        }
    }

    // MARK: - Create Collection Section

    private var createCollectionSection: some View {
        Section {
            Button {
                showCreateSheet = true
            } label: {
                Label("Create New Collection", systemImage: "folder.badge.plus")
            }
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedCollectionIds.contains(id) {
            selectedCollectionIds.remove(id)
        } else {
            selectedCollectionIds.insert(id)
        }
    }

    private func save() {
        // Update quote's collections based on selection
        let selectedCollections = collections.filter { selectedCollectionIds.contains($0.id) }

        // Remove from collections no longer selected
        for collection in quote.collections {
            if !selectedCollectionIds.contains(collection.id) {
                if let index = collection.quotes.firstIndex(where: { $0.id == quote.id }) {
                    collection.quotes.remove(at: index)
                }
            }
        }

        // Add to newly selected collections
        for collection in selectedCollections {
            if !collection.quotes.contains(where: { $0.id == quote.id }) {
                collection.quotes.append(quote)
            }
        }

        // Update quote's collection list
        quote.collections = selectedCollections
        quote.dateModified = Date()

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - CollectionSelectionRow

/// Row for selecting a collection with checkbox.
private struct CollectionSelectionRow: View {

    let collection: Collection
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                // Collection icon
                ZStack {
                    Circle()
                        .fill(collectionColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: collection.icon)
                        .foregroundStyle(collectionColor)
                }

                // Name and quote count
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(collection.name)
                        .foregroundStyle(.primary)

                    Text("\(collection.quoteCount) quotes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var collectionColor: Color {
        CollectionColor(rawValue: collection.colorName)?.color ?? .blue
    }
}

// MARK: - Batch AddToCollectionSheet

/// Sheet for adding multiple quotes to collections at once.
struct BatchAddToCollectionSheet: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries

    @Query(sort: \Collection.sortOrder) private var collections: [Collection]

    // MARK: - Properties

    /// The quotes to add to collections
    let quotes: [Quote]

    // MARK: - State

    @State private var selectedCollectionIds: Set<UUID> = []
    @State private var showCreateSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Info header
                Section {
                    HStack {
                        Image(systemName: "quote.opening")
                            .foregroundStyle(Color.accentColor)
                        Text("\(quotes.count) quote\(quotes.count == 1 ? "" : "s") selected")
                            .foregroundStyle(.secondary)
                    }
                }

                // Collections
                if collections.isEmpty {
                    Section {
                        Text("No collections yet")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(collections) { collection in
                            CollectionSelectionRow(
                                collection: collection,
                                isSelected: selectedCollectionIds.contains(collection.id)
                            ) {
                                toggleSelection(collection.id)
                            }
                        }
                    }
                }

                // Create new
                Section {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label("Create New Collection", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .disabled(selectedCollectionIds.isEmpty)
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CollectionEditorSheet(mode: .create)
            }
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedCollectionIds.contains(id) {
            selectedCollectionIds.remove(id)
        } else {
            selectedCollectionIds.insert(id)
        }
    }

    private func save() {
        let selectedCollections = collections.filter { selectedCollectionIds.contains($0.id) }

        for quote in quotes {
            for collection in selectedCollections {
                if !collection.quotes.contains(where: { $0.id == quote.id }) {
                    collection.quotes.append(quote)
                }
                if !quote.collections.contains(where: { $0.id == collection.id }) {
                    quote.collections.append(collection)
                }
            }
            quote.dateModified = Date()
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add to Collection") {
    AddToCollectionSheet(quote: Quote(text: "Sample quote text for preview"))
        .modelContainer(for: [Collection.self, Quote.self], inMemory: true)
}

#Preview("Batch Add") {
    BatchAddToCollectionSheet(quotes: [
        Quote(text: "Quote 1"),
        Quote(text: "Quote 2"),
        Quote(text: "Quote 3")
    ])
    .modelContainer(for: [Collection.self, Quote.self], inMemory: true)
}
