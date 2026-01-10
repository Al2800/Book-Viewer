import SwiftUI
import SwiftData

// MARK: - BookDetailView

/// Detail view showing book metadata and all associated quotes.
struct BookDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(RouterPath.self) private var router

    // MARK: - Properties

    let book: Book

    // MARK: - State

    @State private var sortOrder: SortOrder = .dateAdded
    @State private var filterMarking: MarkingType?
    @State private var showSortMenu = false
    @State private var showFilterMenu = false

    // MARK: - Sort Order

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case pageNumber = "Page Number"
        case markingType = "Marking Type"
        case favorite = "Favorites First"
    }

    // MARK: - Computed

    private var sortedQuotes: [Quote] {
        var quotes = book.quotes

        // Apply filter
        if let filter = filterMarking {
            quotes = quotes.filter { $0.markingType == filter }
        }

        // Apply sort
        switch sortOrder {
        case .dateAdded:
            quotes.sort { $0.captureDate > $1.captureDate }
        case .pageNumber:
            quotes.sort { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
        case .markingType:
            quotes.sort { $0.markingType.rawValue < $1.markingType.rawValue }
        case .favorite:
            quotes.sort { ($0.isFavorite ? 0 : 1) < ($1.isFavorite ? 0 : 1) }
        }

        return quotes
    }

    private var uniquePages: Int {
        Set(book.quotes.compactMap { $0.pageNumber }).count
    }

    private var markingTypes: [MarkingType] {
        Array(Set(book.quotes.map { $0.markingType })).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header with cover and metadata
                BookHeaderView(book: book)

                // Stats bar
                statsBar

                // Filter/sort controls
                if book.hasQuotes {
                    controlsBar
                }

                // Quotes list or empty state
                if book.quotes.isEmpty {
                    emptyQuotesView
                } else if sortedQuotes.isEmpty {
                    noFilterResultsView
                } else {
                    quotesGrid
                }
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        // TODO: Edit book
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        // TODO: Capture more quotes
                    } label: {
                        Label("Add Quotes", systemImage: "camera")
                    }

                    Divider()

                    Button(role: .destructive) {
                        // TODO: Delete book
                    } label: {
                        Label("Delete Book", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: Spacing.md) {
            StatBadge(
                label: "Quotes",
                value: "\(book.quoteCount)",
                icon: "quote.opening"
            )

            StatBadge(
                label: "Pages",
                value: "\(uniquePages)",
                icon: "doc"
            )

            if let rating = book.rating {
                StatBadge(
                    label: "Rating",
                    value: "\(rating)/5",
                    icon: "star.fill",
                    color: .yellow
                )
            }

            Spacer()
        }
    }

    // MARK: - Controls Bar

    private var controlsBar: some View {
        HStack {
            // Sort menu
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort: \(sortOrder.rawValue)", systemImage: "arrow.up.arrow.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Filter menu
            Menu {
                Button {
                    filterMarking = nil
                } label: {
                    HStack {
                        Text("All Markings")
                        if filterMarking == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(markingTypes, id: \.self) { type in
                    Button {
                        filterMarking = type
                    } label: {
                        HStack {
                            Text(type.displayName)
                            if filterMarking == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(
                    filterMarking?.displayName ?? "Filter",
                    systemImage: filterMarking != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
                )
                .font(.caption)
                .foregroundStyle(filterMarking != nil ? .accent : .secondary)
            }
        }
    }

    // MARK: - Quotes Grid

    private var quotesGrid: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(sortedQuotes) { quote in
                NavigationLink(value: quote) {
                    QuoteCardView(quote: quote)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty States

    private var emptyQuotesView: some View {
        ContentUnavailableView {
            Label("No Quotes Yet", systemImage: "quote.opening")
        } description: {
            Text("Capture pages from this book to start extracting quotes.")
        } actions: {
            Button {
                // TODO: Navigate to capture
            } label: {
                Label("Capture Quotes", systemImage: "camera")
            }
            .buttonStyle(.bordered)
        }
    }

    private var noFilterResultsView: some View {
        ContentUnavailableView {
            Label("No Matching Quotes", systemImage: "magnifyingglass")
        } description: {
            Text("No quotes match the current filter.")
        } actions: {
            Button("Clear Filter") {
                filterMarking = nil
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(book: {
            let book = Book(title: "Atomic Habits", author: "James Clear")
            book.subtitle = "An Easy & Proven Way to Build Good Habits"
            book.status = .currentlyReading

            // Add some sample quotes
            for i in 1...5 {
                let quote = Quote(
                    text: "Sample quote number \(i). This is a longer text to show how quotes appear in the detail view.",
                    book: book
                )
                quote.pageNumber = i * 10
                quote.markingType = [.underline, .highlight, .marginLine][i % 3]
            }

            return book
        }())
    }
    .environment(RouterPath())
}
