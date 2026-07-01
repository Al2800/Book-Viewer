import SwiftUI
import SwiftData

/// Library tab - displays book grid/list with inline search
struct LibraryTab: View {
    @State private var router = RouterPath()

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            NavigationStack(path: $router.path) {
                LibraryView()
                    .navigationDestination(for: Book.self) { book in
                        BookDetailView(book: book)
                    }
                    .navigationDestination(for: Quote.self) { quote in
                        QuoteDetailView(quote: quote)
                    }
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

    @AppStorage("libraryViewMode") private var viewMode: LibraryViewMode = .grid
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .all
    @State private var isSearchActive = false
    @State private var searchServices: LibrarySearchServices?
    @State private var bookToDelete: Book?
    @State private var bookToEdit: Book?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showAddBookSheet = false
    @State private var hasAppeared = false
    @State private var isRefreshing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        mainContent
        .background(Color.backgroundPrimary)
        .overlay(alignment: .topLeading) {
            if UITestConfiguration.isUITesting {
                Text("\(books.count)")
                    .font(.caption2)
                    .opacity(0.01)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Common.uiTestBookCount)
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
            if let searchServices {
                SearchSuggestionsContent(
                    appeared: true,
                    onSelect: { text in
                        searchText = text
                        searchServices.acceptSuggestion(text)
                    },
                    onClearHistory: {
                        searchServices.suggestionsService.clearHistory()
                    }
                )
                .environment(searchServices.suggestionsService)
            }
        }
        .toolbar { toolbarContent }
        .onAppear {
            initializeSearchServices()
            if UITestConfiguration.isUITesting {
                print("UITest library books count: \(books.count)")
            }
            // Trigger entrance animation
            guard !UITestConfiguration.isUITesting, !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.1)) {
                hasAppeared = true
            }
        }
        .onChange(of: books.count) { _, newValue in
            if UITestConfiguration.isUITesting {
                print("UITest library books count updated: \(newValue)")
            }
        }
        .onChange(of: viewMode) { _, _ in
            HapticManager.selection()
        }
        .onChange(of: searchText) { _, newValue in
            guard let searchServices else { return }
            Task {
                await searchServices.updateSuggestions(for: newValue)
            }
        }
        .onChange(of: isSearchActive) { _, isActive in
            guard let searchServices else { return }
            Task {
                await searchServices.handlePresentationChange(isActive: isActive, searchText: searchText)
            }
        }
        .onSubmit(of: .search) {
            searchServices?.submitSearch(searchText)
        }
        .confirmationDialog(
            deletePrompt?.title ?? "Delete Book?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(deletePrompt?.destructiveButtonTitle ?? "Delete Book", role: .destructive) {
                if let book = bookToDelete {
                    deleteBook(book)
                }
            }
            Button("Cancel", role: .cancel) {
                bookToDelete = nil
            }
        } message: {
            if let deletePrompt {
                Text(deletePrompt.message)
            }
        }
        .sheet(isPresented: $showAddBookSheet) {
            BookEditView(mode: .create) { newBook in
                // Navigate to the newly created book
                router.navigate(to: newBook)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let book = bookToEdit {
                BookEditView(mode: .edit(book))
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch LibraryContentMode.resolve(isSearchActive: isSearchActive, searchText: searchText, bookCount: books.count) {
        case .searchResults:
            searchResults
        case .emptyLibrary:
            EmptyLibraryView(onAddBook: { showAddBookSheet = true })
        case .library:
            libraryContent
        }
    }

    private var searchResults: some View {
        Group {
            if let searchServices {
                let navigationLookup = LibraryNavigationLookup(modelContext: modelContext)

                // FTS5-powered search results
                SearchResultsView(
                    searchService: searchServices.searchService,
                    searchText: searchText,
                    scope: searchScope,
                    suggestionsService: searchServices.suggestionsService,
                    onQuoteTap: { quoteId in
                        if let quote = navigationLookup.quote(id: quoteId) {
                            router.navigate(to: quote)
                        }
                    },
                    onBookTap: { bookId in
                        if let book = navigationLookup.book(id: bookId) {
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
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var libraryContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                LibrarySummaryCard(
                    bookCount: books.count,
                    quoteCount: books.reduce(0) { $0 + $1.quoteCount },
                    viewMode: viewMode
                )

                LibrarySectionCard(title: "Browse") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        LibraryControlRow(
                            icon: viewMode.systemImageName,
                            title: "Library View",
                            subtitle: "Switch between cover cards and a compact reading list",
                            trailing: {
                                LibraryViewModeControl(viewMode: $viewMode)
                            }
                        )

                        Button {
                            HapticManager.light()
                            showAddBookSheet = true
                        } label: {
                            LibraryActionRow(
                                icon: "plus",
                                title: "Add New Book",
                                subtitle: "Create a library entry before capturing quotes"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                LibraryBooksSection(
                    books: books,
                    viewMode: $viewMode,
                    hasAppeared: hasAppeared,
                    reduceMotion: reduceMotion,
                    onTap: { book in
                        router.navigate(to: book)
                    },
                    onEdit: { book in
                        bookToEdit = book
                        showEditSheet = true
                    },
                    onDelete: { book in
                        bookToDelete = book
                        showDeleteConfirmation = true
                    }
                )
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.backgroundPrimary)
        .refreshable {
            await refreshLibrary()
        }
        .animation(reduceMotion ? .none : .smoothSpring, value: viewMode)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            addBookButton
        }
    }

    private var addBookButton: some View {
        Button {
            HapticManager.light()
            showAddBookSheet = true
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.addBookButton)
    }

    private var deletePrompt: BookDeletionPrompt? {
        guard let bookToDelete else { return nil }

        return BookDeletionPrompt(
            bookTitle: bookToDelete.title,
            quoteCount: bookToDelete.quoteCount
        )
    }

    // MARK: - Private Methods

    private func initializeSearchServices() {
        guard searchServices == nil else { return }
        do {
            searchServices = try LibrarySearchServices.live()
        } catch {
            print("Failed to initialize SearchService: \(error)")
        }
    }

    /// Refresh library data with pull-to-refresh
    private func refreshLibrary() async {
        isRefreshing = true
        HapticManager.light()

        // Small delay for visual feedback
        try? await Task.sleep(for: .milliseconds(300))

        // Rebuild search index if needed
        if let searchServices {
            await MainActor.run {
                // Trigger re-indexing (SearchService handles this internally)
                searchServices.refreshSearchIndex()
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
