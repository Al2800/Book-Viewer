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

    /// Optional suggestions service for did-you-mean corrections
    var suggestionsService: SearchSuggestionsService?

    /// Action when a quote result is tapped
    var onQuoteTap: ((UUID) -> Void)?

    /// Action when a book result is tapped
    var onBookTap: ((UUID) -> Void)?

    /// Action when user accepts a did-you-mean suggestion
    var onAcceptSuggestion: ((String) -> Void)?

    /// Action when user wants to change search scope
    var onScopeChange: ((SearchScope) -> Void)?

    // MARK: - Animation State

    @State private var hasAppeared = false
    @State private var resultsKey = UUID()

    // MARK: - Did-You-Mean State

    @State private var didYouMeanSuggestion: String?
    @State private var isLoadingSuggestion = false
    private var shouldDisableAnimations: Bool {
        UITestConfiguration.isUITesting || reduceMotion
    }

    private var presentation: SearchResultsPresentation {
        SearchResultsPresentation(
            scope: scope,
            bookCount: searchService.results.books.count,
            quoteCount: searchService.results.quotes.count
        )
    }

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
        .animation(shouldDisableAnimations ? .none : .smoothSpring, value: searchService.isSearching)
        .animation(shouldDisableAnimations ? .none : .smoothSpring, value: searchService.results.isEmpty)
        .onChange(of: searchText) { _, newValue in
            // Clear any existing suggestion when query changes
            didYouMeanSuggestion = nil
            searchService.search(newValue, scope: scope)
        }
        .onChange(of: scope) { _, newScope in
            // Reset animation state for new results
            hasAppeared = false
            searchService.search(searchText, scope: newScope)
            // Trigger staggered entrance for new scope
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard !shouldDisableAnimations else {
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
            if SearchResultsPresentation.shouldResetResultsAnimation(oldCount: oldCount, newCount: newCount) {
                resultsKey = UUID()
                hasAppeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    guard !shouldDisableAnimations else {
                        hasAppeared = true
                        return
                    }
                    withAnimation(.smoothSpring) {
                        hasAppeared = true
                    }
                }
            }

            // Fetch did-you-mean when results are empty and we have a query
            if SearchResultsPresentation.shouldFetchDidYouMean(
                resultCount: newCount,
                searchText: searchText,
                isSearching: searchService.isSearching
            ) {
                fetchDidYouMean()
            }
        }
        .onAppear {
            if !searchText.isEmpty {
                searchService.search(searchText, scope: scope)
            }
            guard !shouldDisableAnimations else {
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
        .opacity(shouldDisableAnimations ? 1 : (hasAppeared ? 1 : 0))
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.searchingIndicator)
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            // Books section
            if presentation.showsBooks {
                booksSection
            }

            // Quotes section
            if presentation.showsQuotes {
                quotesSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.backgroundPrimary)
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .accessibilityIdentifier(AccessibilityIdentifiers.Search.bookResultRow)
                // Staggered entrance animation
                .opacity(shouldDisableAnimations ? 1 : (hasAppeared ? 1 : 0))
                .offset(x: shouldDisableAnimations ? 0 : (hasAppeared ? 0 : -15))
                .animation(
                    shouldDisableAnimations ? .none : .smoothSpring.delay(
                        presentation.bookAnimationDelay(index: index)
                    ),
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .accessibilityIdentifier(AccessibilityIdentifiers.Search.quoteResultRow)
                // Staggered entrance animation (offset by book count)
                .opacity(shouldDisableAnimations ? 1 : (hasAppeared ? 1 : 0))
                .offset(x: shouldDisableAnimations ? 0 : (hasAppeared ? 0 : -15))
                .animation(
                    shouldDisableAnimations ? .none : .smoothSpring.delay(
                        presentation.quoteAnimationDelay(index: index)
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
                .sectionHeaderStyle()
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
                .contentTransition(.numericText())
        }
        .animation(reduceMotion ? .none : .snappy, value: count)
    }

    // MARK: - Empty States

    private var emptySearchView: some View {
        SearchEmptyStateView(
            recentSearches: suggestionsService?.getRecentSearches() ?? [],
            hasAppeared: hasAppeared,
            onSelectRecentSearch: { search in
                HapticManager.light()
                onAcceptSuggestion?(search)
            }
        )
    }

    private var noResultsView: some View {
        SearchNoResultsView(
            searchText: searchText,
            scope: scope,
            recentSearches: suggestionsService?.getRecentSearches() ?? [],
            didYouMeanSuggestion: didYouMeanSuggestion,
            isLoadingSuggestion: isLoadingSuggestion,
            hasAppeared: hasAppeared,
            reduceMotion: reduceMotion,
            onAcceptDidYouMean: acceptSuggestion,
            onSelectRecentSearch: { search in
                HapticManager.light()
                onAcceptSuggestion?(search)
            },
            onSearchAll: {
                HapticManager.light()
                onScopeChange?(.all)
            }
        )
    }

    // MARK: - Error View

    private func errorView(_ error: SearchError) -> some View {
        SearchErrorStateView(error: error) {
            HapticManager.light()
            searchService.search(searchText, scope: scope)
        }
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

    // MARK: - Did-You-Mean

    private func fetchDidYouMean() {
        guard let suggestionsService else { return }
        guard !isLoadingSuggestion else { return }

        isLoadingSuggestion = true

        Task {
            let suggestion = await suggestionsService.didYouMean(searchText)
            await MainActor.run {
                didYouMeanSuggestion = suggestion
                isLoadingSuggestion = false
            }
        }
    }

    private func acceptSuggestion(_ suggestion: String) {
        HapticManager.light()
        didYouMeanSuggestion = nil

        // Add to search history
        suggestionsService?.addToHistory(suggestion)

        // Notify parent to update search text
        onAcceptSuggestion?(suggestion)
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
