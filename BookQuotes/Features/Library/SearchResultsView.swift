import SwiftUI
import SwiftData

// MARK: - SearchResultsView

/// View displaying search results with highlighted matches and context.
struct SearchResultsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Properties

    let searchService: SearchService
    let searchText: String
    let scope: SearchScope

    /// Action when a quote result is tapped
    var onQuoteTap: ((UUID) -> Void)?

    /// Action when a book result is tapped
    var onBookTap: ((UUID) -> Void)?

    // MARK: - Animation State

    @State private var hasAppeared = false
    @State private var resultsKey = UUID()

    // MARK: - Body

    var body: some View {
        Group {
            if searchService.isSearching {
                searchingView
                    .transition(.opacity)
            } else if let error = searchService.lastError {
                errorView(error)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if searchText.isEmpty {
                emptySearchView
                    .transition(.opacity)
            } else if searchService.results.isEmpty {
                noResultsView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                resultsList
                    .id(resultsKey)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .smoothSpring, value: searchService.isSearching)
        .animation(reduceMotion ? .none : .smoothSpring, value: searchService.results.isEmpty)
        .onChange(of: searchText) { _, newValue in
            searchService.search(newValue, scope: scope)
        }
        .onChange(of: scope) { _, newScope in
            // Reset animation state for new results
            hasAppeared = false
            searchService.search(searchText, scope: newScope)
            // Trigger staggered entrance for new scope
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard !reduceMotion else {
                    hasAppeared = true
                    return
                }
                withAnimation(.smoothSpring) {
                    hasAppeared = true
                }
            }
        }
        .onChange(of: searchService.results.books.count + searchService.results.quotes.count) { oldCount, newCount in
            // Trigger re-animation when results change significantly
            if oldCount == 0 && newCount > 0 {
                resultsKey = UUID()
                hasAppeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    guard !reduceMotion else {
                        hasAppeared = true
                        return
                    }
                    withAnimation(.smoothSpring) {
                        hasAppeared = true
                    }
                }
            }
        }
        .onAppear {
            if !searchText.isEmpty {
                searchService.search(searchText, scope: scope)
            }
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.1)) {
                hasAppeared = true
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
        .opacity(hasAppeared ? 1 : 0)
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
            ForEach(Array(searchService.results.books.enumerated()), id: \.element.id) { index, result in
                Button {
                    HapticManager.light()
                    onBookTap?(result.bookId)
                } label: {
                    BookSearchResultRow(
                        result: result,
                        query: searchText,
                        book: fetchBook(id: result.bookId)
                    )
                }
                .buttonStyle(.plain)
                // Staggered entrance animation
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -15)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.04),
                    value: hasAppeared
                )
            }
        } header: {
            sectionHeader("Books", count: searchService.results.books.count)
        }
    }

    private var quotesSection: some View {
        Section {
            ForEach(Array(searchService.results.quotes.enumerated()), id: \.element.id) { index, result in
                Button {
                    HapticManager.light()
                    onQuoteTap?(result.quoteId)
                } label: {
                    QuoteSearchResultRow(
                        result: result,
                        query: searchText,
                        quote: fetchQuote(id: result.quoteId)
                    )
                }
                .buttonStyle(.plain)
                // Staggered entrance animation (offset by book count)
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -15)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(
                        Double(min(searchService.results.books.count + index, 12)) * 0.04
                    ),
                    value: hasAppeared
                )
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
                .contentTransition(.numericText())
        }
        .animation(reduceMotion ? .none : .snappy, value: count)
    }

    // MARK: - Empty States

    private var emptySearchView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
                .symbolEffect(.pulse, options: .repeating)

            Text("Search your library")
                .font(.headline)

            Text("Find quotes and books by title, author, or content")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
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
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95)
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
