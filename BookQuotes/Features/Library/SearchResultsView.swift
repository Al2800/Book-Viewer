import SwiftUI
import SwiftData

// MARK: - SearchResultsView

/// View displaying search results with highlighted matches and context.
struct SearchResultsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let searchService: SearchService
    let searchText: String
    let scope: SearchScope

    /// Action when a quote result is tapped
    var onQuoteTap: ((UUID) -> Void)?

    /// Action when a book result is tapped
    var onBookTap: ((UUID) -> Void)?

    // MARK: - Body

    var body: some View {
        Group {
            if searchService.isSearching {
                searchingView
            } else if let error = searchService.lastError {
                errorView(error)
            } else if searchText.isEmpty {
                emptySearchView
            } else if searchService.results.isEmpty {
                noResultsView
            } else {
                resultsList
            }
        }
        .onChange(of: searchText) { _, newValue in
            searchService.search(newValue, scope: scope)
        }
        .onChange(of: scope) { _, newScope in
            searchService.search(searchText, scope: newScope)
        }
        .onAppear {
            if !searchText.isEmpty {
                searchService.search(searchText, scope: scope)
            }
        }
    }

    // MARK: - Loading View

    private var searchingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.searchingIndicator)
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            // Books section
            if !searchService.results.books.isEmpty &&
               (scope == .all || scope == .books) {
                booksSection
            }

            // Quotes section
            if !searchService.results.quotes.isEmpty &&
               (scope == .all || scope == .quotes) {
                quotesSection
            }
        }
        .listStyle(.insetGrouped)
    }

    private var booksSection: some View {
        Section {
            ForEach(searchService.results.books) { result in
                Button {
                    onBookTap?(result.bookId)
                } label: {
                    BookSearchResultRow(
                        result: result,
                        query: searchText,
                        book: fetchBook(id: result.bookId)
                    )
                }
                .buttonStyle(.plain)
            }
        } header: {
            sectionHeader("Books", count: searchService.results.books.count)
        }
    }

    private var quotesSection: some View {
        Section {
            ForEach(searchService.results.quotes) { result in
                Button {
                    onQuoteTap?(result.quoteId)
                } label: {
                    QuoteSearchResultRow(
                        result: result,
                        query: searchText,
                        quote: fetchQuote(id: result.quoteId)
                    )
                }
                .buttonStyle(.plain)
            }
        } header: {
            sectionHeader("Quotes", count: searchService.results.quotes.count)
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty States

    private var emptySearchView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)

            Text("Search your library")
                .font(.headline)

            Text("Find quotes and books by title, author, or content")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No results for '\(searchText)'")
                .font(.headline)

            Text("Try different keywords or check spelling")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Suggestions
            suggestionButtons
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.noResultsView)
    }

    private var suggestionButtons: some View {
        VStack(spacing: Spacing.sm) {
            if scope != .all {
                Button {
                    // Let parent handle scope change
                } label: {
                    Label("Search all", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ error: SearchError) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.error)

            Text("Search error")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try again") {
                searchService.search(searchText, scope: scope)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Fetching

    private func fetchBook(id: UUID) -> Book? {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchQuote(id: UUID) -> Quote? {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var searchText = "habits"

        var body: some View {
            NavigationStack {
                if let service = try? SearchService() {
                    SearchResultsView(
                        searchService: service,
                        searchText: searchText,
                        scope: .all
                    )
                    .navigationTitle("Search")
                    .searchable(text: $searchText)
                }
            }
        }
    }

    return PreviewContainer()
        .modelContainer(for: [Book.self, Quote.self])
}
