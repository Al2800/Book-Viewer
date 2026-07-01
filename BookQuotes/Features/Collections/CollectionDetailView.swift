import SwiftUI
import SwiftData

// MARK: - CollectionDetailView

/// Displays all quotes within a collection with management options.
struct CollectionDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var collection: Collection

    // MARK: - State

    @State private var showEditSheet = false
    @State private var showAddQuotesSheet = false
    @State private var showDeleteConfirmation = false
    @State private var sortOrder: CollectionQuoteSortOrder = .dateAdded
    @State private var searchText = ""

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier(AccessibilityIdentifiers.Collections.detailView)
            .toolbar { toolbarContent }
            .searchable(text: $searchText, prompt: "Search quotes")
            .sheet(isPresented: $showEditSheet) {
                CollectionEditorSheet(mode: .edit(collection))
            }
            .sheet(isPresented: $showAddQuotesSheet) {
                AddQuotesToCollectionSheet(collection: collection)
            }
            .confirmationDialog(
                "Delete Collection?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteConfirmationActions
            } message: {
                Text("This will delete the collection but keep all quotes. This cannot be undone.")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if collection.quotes.isEmpty {
            emptyState
        } else {
            quoteList
        }
    }

    // MARK: - Quote List

    private var quoteList: some View {
        CollectionDetailQuoteList(
            collection: collection,
            quotes: sortedAndFilteredQuotes,
            sortOrder: $sortOrder,
            onRemove: removeFromCollection,
            onToggleFavorite: toggleFavorite
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        CollectionDetailEmptyState {
            showAddQuotesSheet = true
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        CollectionDetailToolbarMenu(
            onAddQuotes: { showAddQuotesSheet = true },
            onEdit: { showEditSheet = true },
            onDelete: { showDeleteConfirmation = true }
        )
    }

    // MARK: - Delete Confirmation

    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button("Delete Collection", role: .destructive) {
            deleteCollection()
        }

        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Computed Properties

    private var sortedAndFilteredQuotes: [Quote] {
        var quotes = collection.quotes

        // Filter by search
        if !searchText.isEmpty {
            quotes = quotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.book?.title.localizedCaseInsensitiveContains(searchText) == true ||
                quote.marginNote?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Sort
        switch sortOrder {
        case .dateAdded:
            quotes.sort { $0.captureDate > $1.captureDate }
        case .bookTitle:
            quotes.sort { ($0.book?.title ?? "") < ($1.book?.title ?? "") }
        case .pageNumber:
            quotes.sort { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
        }

        return quotes
    }

    // MARK: - Actions

    private func removeFromCollection(_ quote: Quote) {
        if let index = collection.quotes.firstIndex(where: { $0.id == quote.id }) {
            collection.quotes.remove(at: index)
            collection.dateModified = Date()
            try? modelContext.save()
        }
    }

    private func toggleFavorite(_ quote: Quote) {
        quote.isFavorite.toggle()
        quote.dateModified = Date()
        try? modelContext.save()
    }

    private func deleteCollection() {
        modelContext.delete(collection)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview("Collection Detail") {
    NavigationStack {
        CollectionDetailView(collection: Collection(name: "Favorites", icon: "star.fill", colorName: "yellow"))
    }
    .modelContainer(for: [Collection.self, Quote.self, Book.self], inMemory: true)
}

#Preview("Add Quotes Sheet") {
    AddQuotesToCollectionSheet(collection: Collection(name: "Test", icon: "folder", colorName: "blue"))
        .modelContainer(for: [Collection.self, Quote.self, Book.self], inMemory: true)
}
