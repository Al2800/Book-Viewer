import SwiftData
import SwiftUI

enum CollectionQuoteSortOrder: String, CaseIterable {
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

struct CollectionDetailQuoteList: View {
    let collection: Collection
    let quotes: [Quote]
    @Binding var sortOrder: CollectionQuoteSortOrder
    let onRemove: (Quote) -> Void
    let onToggleFavorite: (Quote) -> Void

    var body: some View {
        List {
            CollectionDetailHeaderSection(collection: collection, sortOrder: $sortOrder)

            ForEach(quotes) { quote in
                NavigationLink(value: quote) {
                    QuoteCardView(quote: quote, showBookInfo: true, style: .compact)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    SwipeActionStyle.removeButton {
                        onRemove(quote)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    SwipeActionStyle.favoriteButton(isFavorite: quote.isFavorite) {
                        onToggleFavorite(quote)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct CollectionDetailHeaderSection: View {
    let collection: Collection
    @Binding var sortOrder: CollectionQuoteSortOrder

    private var collectionColor: Color {
        CollectionColor.named(collection.colorName).color
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
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

                        if !collection.books.isEmpty {
                            Text("from \(collection.books.count) \(collection.books.count == 1 ? "book" : "books")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                if let description = collection.collectionDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Picker("Sort by", selection: $sortOrder) {
                    ForEach(CollectionQuoteSortOrder.allCases, id: \.self) { order in
                        Label(order.rawValue, systemImage: order.systemImage)
                            .tag(order)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

struct CollectionDetailEmptyState: View {
    let onAddQuotes: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "quote.opening",
            title: "No Quotes Yet",
            message: "Add quotes to this collection from your library.",
            action: ("Add Quotes", onAddQuotes)
        )
    }
}

struct CollectionDetailToolbarMenu: ToolbarContent {
    let onAddQuotes: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    onAddQuotes()
                } label: {
                    Label("Add Quotes", systemImage: "plus")
                }

                Button {
                    onEdit()
                } label: {
                    Label("Edit Collection", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Collection", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Common.moreMenuButton)
        }
    }
}

/// Sheet for adding quotes to a collection from the library.
struct AddQuotesToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Quote.captureDate, order: .reverse) private var allQuotes: [Quote]

    let collection: Collection

    @State private var selectedQuoteIds: Set<UUID> = []
    @State private var searchText = ""
    @State private var selectedBook: Book?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !availableBooks.isEmpty {
                    bookFilterPicker
                }

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

    private var availableBooks: [Book] {
        let bookIds = Set(allQuotes.compactMap { $0.book?.id })
        return allQuotes.compactMap { $0.book }.filter { bookIds.contains($0.id) }
            .uniqued(on: \.id)
    }

    private var filteredQuotes: [Quote] {
        var quotes = allQuotes
        let existingIds = Set(collection.quotes.map { $0.id })
        quotes = quotes.filter { !existingIds.contains($0.id) }

        if let book = selectedBook {
            quotes = quotes.filter { $0.book?.id == book.id }
        }

        if !searchText.isEmpty {
            quotes = quotes.filter { quote in
                quote.text.localizedCaseInsensitiveContains(searchText) ||
                quote.book?.title.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return quotes
    }

    private func toggleSelection(_ id: UUID) {
        if selectedQuoteIds.contains(id) {
            selectedQuoteIds.remove(id)
        } else {
            selectedQuoteIds.insert(id)
        }
    }

    private func addSelectedQuotes() {
        let quotesToAdd = allQuotes.filter { selectedQuoteIds.contains($0.id) }
        for quote in quotesToAdd where !collection.quotes.contains(where: { $0.id == quote.id }) {
            collection.quotes.append(quote)
        }
        collection.dateModified = Date()
        try? modelContext.save()
        dismiss()
    }
}

private struct QuoteSelectionRow: View {
    let quote: Quote
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.brand : .secondary)
                .font(.title3)

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
                .foregroundStyle(isSelected ? Color.brand : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension Array {
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
