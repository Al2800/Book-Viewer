import SwiftUI
import SwiftData

/// Library tab - displays book grid/list with inline search
struct LibraryTab: View {
    @State private var router = RouterPath()

    var body: some View {
        NavigationStack(path: $router.path) {
            LibraryView()
                .navigationDestination(for: Book.self) { book in
                    BookDetailView(book: book)
                }
                .navigationDestination(for: Quote.self) { quote in
                    QuoteDetailView(quote: quote)
                }
        }
        .environment(router)
    }
}

// MARK: - Placeholder Views

/// Main library view showing books with grid/list toggle and FTS5 search
struct LibraryView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(RouterPath.self) private var router

    // MARK: - Query

    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]

    // MARK: - State

    @AppStorage("libraryViewMode") private var viewMode: ViewMode = .grid
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .all
    @State private var isSearchActive = false
    @State private var searchService: SearchService?
    @State private var suggestionsService: SearchSuggestionsService?
    @State private var bookToDelete: Book?
    @State private var showDeleteConfirmation = false
    @State private var showAddBookSheet = false
    @State private var hasAppeared = false
    @State private var isRefreshing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - View Mode

    enum ViewMode: String {
        case grid, list
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isSearchActive && !searchText.isEmpty, let service = searchService {
                // FTS5-powered search results
                SearchResultsView(
                    searchService: service,
                    searchText: searchText,
                    scope: searchScope,
                    suggestionsService: suggestionsService,
                    onQuoteTap: { quoteId in
                        if let quote = fetchQuote(id: quoteId) {
                            router.navigate(to: quote)
                        }
                    },
                    onBookTap: { bookId in
                        if let book = fetchBook(id: bookId) {
                            router.navigate(to: book)
                        }
                    },
                    onAcceptSuggestion: { suggestion in
                        searchText = suggestion
                    },
                    onScopeChange: { newScope in
                        searchScope = newScope
                    }
                )
            } else if books.isEmpty {
                EmptyLibraryView(onAddBook: { showAddBookSheet = true })
            } else {
                // Normal library view with animated transitions
                Group {
                    switch viewMode {
                    case .grid:
                        bookGrid
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                    case .list:
                        bookList
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                    }
                }
                .animation(reduceMotion ? .none : .smoothSpring, value: viewMode)
            }
        }
        .navigationTitle("Library")
        .searchable(
            text: $searchText,
            isPresented: $isSearchActive,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search books and quotes"
        )
        .searchScopes($searchScope, activation: .onSearchPresentation) {
            Text("All").tag(SearchScope.all)
            Text("Books").tag(SearchScope.books)
            Text("Quotes").tag(SearchScope.quotes)
        }
        .searchSuggestions {
            if let suggestionsService {
                SearchSuggestionsContent(
                    appeared: true,
                    onSelect: { text in
                        searchText = text
                        suggestionsService.addToHistory(text)
                    },
                    onClearHistory: {
                        suggestionsService.clearHistory()
                    }
                )
                .environment(suggestionsService)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.viewModeToggle)

                // Add book button
                Button {
                    HapticManager.light()
                    showAddBookSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.addBookButton)
            }
        }
        .onAppear {
            initializeSearchServices()
            // Trigger entrance animation
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.1)) {
                hasAppeared = true
            }
        }
        .onChange(of: viewMode) { _, _ in
            HapticManager.selection()
        }
        .onChange(of: searchText) { _, newValue in
            guard let suggestionsService else { return }
            Task {
                await suggestionsService.getSuggestions(for: newValue)
            }
        }
        .onChange(of: isSearchActive) { _, isActive in
            guard let suggestionsService else { return }
            if isActive {
                Task {
                    await suggestionsService.getSuggestions(for: searchText)
                }
            } else {
                suggestionsService.clearSuggestions()
            }
        }
        .onSubmit(of: .search) {
            suggestionsService?.addToHistory(searchText)
        }
        .confirmationDialog(
            "Delete \"\(bookToDelete?.title ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Book and All Quotes", role: .destructive) {
                if let book = bookToDelete {
                    deleteBook(book)
                }
            }
            Button("Cancel", role: .cancel) {
                bookToDelete = nil
            }
        } message: {
            if let book = bookToDelete {
                Text("This will permanently delete the book and all \(book.quoteCount) quote\(book.quoteCount == 1 ? "" : "s"). This cannot be undone.")
            }
        }
        .sheet(isPresented: $showAddBookSheet) {
            BookEditView(mode: .create) { newBook in
                // Navigate to the newly created book
                router.navigate(to: newBook)
            }
        }
    }

    // MARK: - Grid View

    private var bookGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)],
                spacing: Spacing.lg
            ) {
                ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                    NavigationLink(value: book) {
                        BookCoverCard(book: book)
                    }
                    .buttonStyle(.plain)
                    // Staggered entrance animation
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(
                        reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                        value: hasAppeared
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await refreshLibrary()
        }
    }

    // MARK: - List View

    private var bookList: some View {
        List {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                NavigationLink(value: book) {
                    BookListRow(book: book)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    SwipeActionStyle.deleteButton {
                        bookToDelete = book
                        showDeleteConfirmation = true
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    SwipeActionStyle.editButton {
                        // Navigate to edit book (will be handled via navigation)
                        router.navigate(to: book)
                    }
                }
                // Staggered entrance animation
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -20)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                    value: hasAppeared
                )
            }
        }
        .listStyle(.plain)
        .refreshable {
            await refreshLibrary()
        }
    }

    // MARK: - Private Methods

    private func initializeSearchServices() {
        guard searchService == nil || suggestionsService == nil else { return }
        do {
            let searchDB = try SearchDatabase()
            searchService = SearchService(database: searchDB)
            suggestionsService = SearchSuggestionsService(searchDB: searchDB)
        } catch {
            print("Failed to initialize SearchService: \(error)")
        }
    }

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

    /// Refresh library data with pull-to-refresh
    private func refreshLibrary() async {
        isRefreshing = true
        HapticManager.light()

        // Small delay for visual feedback
        try? await Task.sleep(for: .milliseconds(300))

        // Rebuild search index if needed
        if let service = searchService {
            await MainActor.run {
                // Trigger re-indexing (SearchService handles this internally)
                service.search("", scope: .all)
            }
        }

        // Reset entrance animation for refreshed content
        await MainActor.run {
            hasAppeared = false
        }

        // Brief delay then re-trigger entrance animation
        try? await Task.sleep(for: .milliseconds(100))

        await MainActor.run {
            guard !reduceMotion else {
                hasAppeared = true
                isRefreshing = false
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
            isRefreshing = false
            HapticManager.success()
        }
    }

    private func deleteBook(_ book: Book) {
        withAnimation {
            modelContext.delete(book)
            do {
                try modelContext.save()
                HapticManager.notification(.success)
            } catch {
                HapticManager.error()
            }
        }
        bookToDelete = nil
    }
}

/// Empty state for library with entrance animation
struct EmptyLibraryView: View {
    /// Callback when user taps "Add Your First Book"
    var onAddBook: (() -> Void)?

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ContentUnavailableView {
            Label("No Books Yet", systemImage: "books.vertical")
        } description: {
            Text("Capture your first book cover to start building your library.")
        } actions: {
            Button {
                HapticManager.light()
                onAddBook?()
            } label: {
                Label("Add Your First Book", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.emptyState)
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }
}




#Preview {
    Group {
        if let container = ModelContainer.preview {
            LibraryTab()
                .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
