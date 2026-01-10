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
    @State private var sortOrder: SortOrder = .dateAdded
    @State private var searchText = ""

    // MARK: - Sort Order

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case bookTitle = "Book"
        case pageNumber = "Page"

        var systemImage: String {
            switch self {
            case .dateAdded: return "calendar"
            case .bookTitle: return "book"
            case .pageNumber: return "number"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.large)
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
        List {
            // Header with collection info
            headerSection

            // Quotes
            ForEach(sortedAndFilteredQuotes) { quote in
                NavigationLink(value: quote) {
                    QuoteCardView(quote: quote, showBookInfo: true, style: .compact)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        removeFromCollection(quote)
                    } label: {
                        Label("Remove", systemImage: "minus.circle")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Collection icon and color
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(collectionColor.opacity(0.15))
                            .frame(width: 50, height: 50)

                        Image(systemName: collection.icon)
                            .font(.title2)
                            .foregroundStyle(collectionColor)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("\(collection.quotes.count) \(collection.quotes.count == 1 ? "quote" : "quotes")")
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        if collection.books.count > 0 {
                            Text("from \(collection.books.count) \(collection.books.count == 1 ? "book" : "books")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                // Description if present
                if let description = collection.collectionDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Sort picker
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Label(order.rawValue, systemImage: order.systemImage)
                            .tag(order)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "quote.opening",
            title: "No Quotes Yet",
            message: "Add quotes to this collection from your library.",
            action: ("Add Quotes", { showAddQuotesSheet = true })
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    showAddQuotesSheet = true
                } label: {
                    Label("Add Quotes", systemImage: "plus")
                }

                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Collection", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Collection", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
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

    private var collectionColor: Color {
        CollectionColor(rawValue: collection.colorName)?.color ?? .blue
    }

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

    private func deleteCollection() {
        modelContext.delete(collection)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - AddQuotesToCollectionSheet

/// Sheet for adding quotes to a collection from the library.
struct AddQuotesToCollectionSheet: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \Quote.captureDate, order: .reverse) private var allQuotes: [Quote]

    // MARK: - Properties

    let collection: Collection

    // MARK: - State

    @State private var selectedQuoteIds: Set<UUID> = []
    @State private var searchText = ""
    @State private var selectedBook: Book?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Book filter
                if !availableBooks.isEmpty {
                    bookFilterPicker
                }

                // Quote list
                List(filteredQuotes, selection: $selectedQuoteIds) { quote in
                    QuoteSelectionRow(quote: quote, isSelected: selectedQuoteIds.contains(quote.id))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(quote.id)
                        }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search quotes")
            }
            .navigationTitle("Add Quotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedQuoteIds.count))") {
                        addSelectedQuotes()
                    }
                    .disabled(selectedQuoteIds.isEmpty)
                }
            }
        }
    }

    // MARK: - Book Filter

    private var bookFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(label: "All Books", isSelected: selectedBook == nil) {
                    selectedBook = nil
                }

                ForEach(availableBooks) { book in
                    FilterChip(label: book.title, isSelected: selectedBook?.id == book.id) {
                        selectedBook = book
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(Color.backgroundSecondary.opacity(0.5))
    }

    // MARK: - Computed Properties

    private var availableBooks: [Book] {
        let bookIds = Set(allQuotes.compactMap { $0.book?.id })
        return allQuotes.compactMap { $0.book }.filter { bookIds.contains($0.id) }
            .uniqued(on: \.id)
    }

    private var filteredQuotes: [Quote] {
        var quotes = allQuotes

        // Exclude quotes already in collection
        let existingIds = Set(collection.quotes.map { $0.id })
        quotes = quotes.filter { !existingIds.contains($0.id) }

        // Filter by book
        if let book = selectedBook {
            quotes = quotes.filter { $0.book?.id == book.id }
        }

        // Filter by search
        if !searchText.isEmpty {
            quotes = quotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.book?.title.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return quotes
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedQuoteIds.contains(id) {
            selectedQuoteIds.remove(id)
        } else {
            selectedQuoteIds.insert(id)
        }
    }

    private func addSelectedQuotes() {
        let quotesToAdd = allQuotes.filter { selectedQuoteIds.contains($0.id) }
        for quote in quotesToAdd {
            if !collection.quotes.contains(where: { $0.id == quote.id }) {
                collection.quotes.append(quote)
            }
        }
        collection.dateModified = Date()
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - QuoteSelectionRow

/// Row for selecting a quote in the add sheet.
private struct QuoteSelectionRow: View {
    let quote: Quote
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .accent : .secondary)
                .font(.title3)

            // Quote preview
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(quote.text)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if let book = quote.book {
                    Text(book.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - FilterChip

/// Small chip for filtering by book.
private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.accent.opacity(0.2) : Color.backgroundSecondary)
                .foregroundStyle(isSelected ? .accent : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Array Extension

extension Array {
    func uniqued<T: Hashable>(on keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { element in
            let key = element[keyPath: keyPath]
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
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
