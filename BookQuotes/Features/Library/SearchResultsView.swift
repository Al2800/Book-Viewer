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
            if oldCount == 0 && newCount > 0 {
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
            if newCount == 0 && !searchText.isEmpty && !searchService.isSearching {
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
                    shouldDisableAnimations ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.04),
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
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)
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
        VStack(spacing: Spacing.lg) {
            // Header section
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

            // Recent searches section
            if let service = suggestionsService {
                let recentSearches = service.getRecentSearches()
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recent Searches")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.xs)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(recentSearches.prefix(5), id: \.self) { search in
                                    Button {
                                        HapticManager.light()
                                        onAcceptSuggestion?(search)
                                    } label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                            Text(search)
                                                .lineLimit(1)
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.backgroundSecondary)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.top, Spacing.md)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
    }

    private var noResultsView: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("No results for '\(searchText)'")
                    .font(.headline)
            }

            // Did-you-mean banner
            if let suggestion = didYouMeanSuggestion {
                DidYouMeanBanner(
                    suggestion: suggestion,
                    onAccept: {
                        acceptSuggestion(suggestion)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if isLoadingSuggestion {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Looking for suggestions...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Action suggestions
            VStack(spacing: Spacing.sm) {
                Text("Try these:")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                // Suggestion buttons
                suggestionButtons

                // Recent searches as alternatives
                if let service = suggestionsService {
                    let recentSearches = service.getRecentSearches()
                        .filter { !$0.lowercased().contains(searchText.lowercased()) }
                    if !recentSearches.isEmpty {
                        VStack(spacing: Spacing.sm) {
                            Divider()
                                .padding(.vertical, Spacing.xs)

                            Text("Or try a recent search")
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.sm) {
                                    ForEach(recentSearches.prefix(4), id: \.self) { search in
                                        Button {
                                            HapticManager.light()
                                            onAcceptSuggestion?(search)
                                        } label: {
                                            Text(search)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .padding(.horizontal, Spacing.md)
                                                .padding(.vertical, Spacing.sm)
                                                .background(Color.backgroundSecondary)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95)
        .animation(reduceMotion ? .none : .smoothSpring, value: didYouMeanSuggestion)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.noResultsView)
    }

    private var suggestionButtons: some View {
        VStack(spacing: Spacing.sm) {
            if scope != .all {
                Button {
                    HapticManager.light()
                    onScopeChange?(.all)
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
                .foregroundStyle(Color.error)

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
