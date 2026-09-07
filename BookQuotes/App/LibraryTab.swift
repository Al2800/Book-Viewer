import SwiftUI
import SwiftData

/// Library tab - displays book grid/list with inline search
struct LibraryTab: View {
    @State private var router = RouterPath()
    @Binding private var bookToOpen: Book?
    var onOpenSettings: (() -> Void)?

    init(
        bookToOpen: Binding<Book?> = .constant(nil),
        onOpenSettings: (() -> Void)? = nil
    ) {
        self._bookToOpen = bookToOpen
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            NavigationStack(path: $router.path) {
                LibraryView(onOpenSettings: onOpenSettings)
                    .navigationDestination(for: Book.self) { book in
                        BookDetailView(book: book)
                    }
                    .navigationDestination(for: Quote.self) { quote in
                        QuoteDetailView(quote: quote)
                    }
                    .navigationDestination(for: LibraryDestination.self) { destination in
                        switch destination {
                        case .collections:
                            CollectionsView()
                        case .tags:
                            TagsView()
                        case .allPassages:
                            LibraryAllPassagesView()
                        }
                    }
                    .navigationDestination(for: Collection.self) { collection in
                        CollectionDetailView(collection: collection)
                    }
            }
        }
        .environment(router)
        .onAppear {
            openPendingBookIfNeeded()
        }
        .onChange(of: bookToOpen?.id) { _, _ in
            openPendingBookIfNeeded()
        }
    }

    private func openPendingBookIfNeeded() {
        guard let book = bookToOpen else { return }
        bookToOpen = nil
        router.popToRoot()
        router.navigate(to: book)
    }
}

/// Non-model destinations within the canonical Reading navigation stack.
enum LibraryDestination: Hashable {
    case collections
    case tags
    case allPassages
}

// MARK: - Placeholder Views

/// Main library view showing books with grid/list toggle and FTS5 search
struct LibraryView: View {
    var onOpenSettings: (() -> Void)? = nil

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(RouterPath.self) private var router

    // MARK: - Query

    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]

    // MARK: - State

    @AppStorage(LibraryViewMode.storageKey) private var viewMode: LibraryViewMode = .defaultMode
    @AppStorage("librarySortOrder") private var sortOrder: LibrarySortOrder = .recent
    @AppStorage(ProductExperience.v2StorageKey) private var productExperienceV2Enabled = ProductExperience.defaultEnabled
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .all
    @State private var isSearchActive = false
    @State private var searchServices: LibrarySearchServices?
    @State private var bookToDelete: Book?
    @State private var bookToEdit: Book?
    @State private var showDeleteConfirmation = false
    @State private var showAddBookCapture = false
    @State private var activeBookToCapture: Book?
    @State private var isRefreshing = false
    @State private var selectedCollectionIds: Set<UUID> = []
    @State private var selectedTagIds: Set<UUID> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var readingHomeTitle: String {
        ProductExperience.usesV2(storedValue: productExperienceV2Enabled) ? "Reading" : "Library"
    }

    // MARK: - Body

    var body: some View {
        // One pass over the library's quotes per render; every consumer
        // below (summary count, daily passage, index-sync trigger) reads
        // from this snapshot instead of walking the quote graph again.
        let snapshot = LibraryHomeSnapshot(books: books)

        mainContent(snapshot: snapshot)
        .background(Color.backgroundPrimary)
        .overlay(alignment: .topLeading) {
            if UITestConfiguration.isUITesting {
                Text("\(books.count)")
                    .font(.caption2)
                    .foregroundStyle(Color.clear)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Common.uiTestBookCount)
            }
        }
        .navigationTitle(readingHomeTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            isPresented: $isSearchActive,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search your reading"
        )
        .searchScopes($searchScope, activation: .onSearchPresentation) {
            Text("All").tag(SearchScope.all)
            Text("Books").tag(SearchScope.books)
            Text("Passages").tag(SearchScope.quotes)
        }
        .searchSuggestions {
            // Native suggestions sit above the result list on iOS. Keep history
            // available before typing, but do not intercept taps on live results.
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let searchServices {
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
            syncSearchIndex()
            if UITestConfiguration.isUITesting {
                print("UITest library books count: \(books.count)")
            }
        }
        .onChange(of: books.count) { _, newValue in
            syncSearchIndex()
            if UITestConfiguration.isUITesting {
                print("UITest library books count updated: \(newValue)")
            }
        }
        .onChange(of: snapshot.totalQuoteCount) { _, _ in
            syncSearchIndex()
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
        .alert(
            deletePrompt?.title ?? "Delete Book?",
            isPresented: $showDeleteConfirmation
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
        .fullScreenCover(isPresented: $showAddBookCapture) {
            // Camera-first book registration: scan the cover (or ISBN barcode),
            // with manual entry available as a fallback inside the flow.
            CoverCaptureFlowView(
                onComplete: { newBook in
                    showAddBookCapture = false
                    router.navigate(to: newBook)
                },
                onCancel: {
                    showAddBookCapture = false
                }
            )
        }
        .fullScreenCover(item: $activeBookToCapture) { book in
            CaptureTabRootView(
                initialBook: book,
                onViewPassages: { savedBook in
                    activeBookToCapture = nil
                    router.navigate(to: savedBook)
                },
                onExit: { activeBookToCapture = nil }
            )
        }
        .sheet(item: $bookToEdit) { book in
            BookEditView(mode: .edit(book))
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(snapshot: LibraryHomeSnapshot) -> some View {
        switch LibraryContentMode.resolve(isSearchActive: isSearchActive, searchText: searchText, bookCount: books.count) {
        case .searchResults:
            searchResults
        case .emptyLibrary:
            EmptyLibraryView(onAddBook: { showAddBookCapture = true })
        case .library:
            libraryContent(snapshot: snapshot)
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
                        } else {
                            refreshStaleSearchResults()
                        }
                    },
                    onBookTap: { bookId in
                        if let book = navigationLookup.book(id: bookId) {
                            router.navigate(to: book)
                        } else {
                            refreshStaleSearchResults()
                        }
                    },
                    onAcceptSuggestion: { suggestion in
                        searchText = suggestion
                    },
                    onScopeChange: { newScope in
                        searchScope = newScope
                    },
                    onDismiss: {
                        searchText = ""
                        isSearchActive = false
                    }
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func libraryContent(snapshot: LibraryHomeSnapshot) -> some View {
        // Keep the ScrollView primary for native large-title behaviour.
        // Organization filters belong inside the Books section they affect.
        libraryScrollContent(snapshot: snapshot)
            .background(Color.backgroundPrimary)
    }

    private func libraryScrollContent(snapshot: LibraryHomeSnapshot) -> some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // 1. Compact active book with direct capture
                if let activeBook = snapshot.activeBook {
                    ContinueReadingCard(
                        book: activeBook,
                        onOpenBook: {
                            router.navigate(to: activeBook)
                        },
                        onCapture: {
                            activeBookToCapture = activeBook
                        }
                    )
                }

                // 2. Recent Passages (Passage-first reading memory)
                if !snapshot.recentQuotes.isEmpty {
                    RecentPassagesSection(
                        quotes: snapshot.recentQuotes,
                        onSelectQuote: { quote in
                            router.navigate(to: quote)
                        }
                    )
                }

                // 3. Revisit (Daily Serendipity / Epigraph)
                if let passage = snapshot.dailyPassage {
                    Button {
                        HapticManager.light()
                        router.navigate(to: passage)
                    } label: {
                        DailyPassageCard(quote: passage)
                    }
                    .buttonStyle(.plain)
                }

                // 4. Books Section with clean inline browse controls
                if !books.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        booksHeader

                        OrganizationFilterBar(
                            selectedCollectionIds: $selectedCollectionIds,
                            selectedTagIds: $selectedTagIds
                        )

                        if hasOrganizationFilters && organizationFilteredBooks.isEmpty {
                            LibraryFilteredBooksEmptyCard()
                        } else {
                            LibraryBooksSection(
                                books: sortOrder.sorted(organizationFilteredBooks),
                                viewMode: $viewMode,
                                onTap: { book in
                                    router.navigate(to: book)
                                },
                                onEdit: { book in
                                    bookToEdit = book
                                },
                                onDelete: { book in
                                    bookToDelete = book
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }

                // 5. Organize Section (Collections & Tags - Clean, zero subtitle clutter)
                LibraryOrganizeSection()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
        .refreshable {
            await refreshLibrary()
        }
        .animation(reduceMotion ? .none : .smoothSpring, value: viewMode)
    }

    private var booksHeader: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))
        return layout {
            HStack(spacing: Spacing.sm) {
                Text("Books").sectionHeaderStyle()
                Text("\(organizationFilteredBooks.count)")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            LibraryBrowseControls(viewMode: $viewMode, sortOrder: $sortOrder)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if ProductExperience.usesV2(storedValue: productExperienceV2Enabled),
           let onOpenSettings {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticManager.light()
                    onOpenSettings()
                } label: {
                    Image(systemName: "gear")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Settings")
                .accessibilityIdentifier(AccessibilityIdentifiers.V2.settingsButton)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            addBookButton
        }
    }

    private var addBookButton: some View {
        Button {
            HapticManager.light()
            showAddBookCapture = true
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Add book")
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.addBookButton)
    }

    // MARK: - Organization Filters

    private var hasOrganizationFilters: Bool {
        !selectedCollectionIds.isEmpty || !selectedTagIds.isEmpty
    }

    private var organizationFilteredBooks: [Book] {
        books.filtered(byCollectionIds: selectedCollectionIds, tagIds: selectedTagIds)
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

    /// Resync the FTS index with the current library so search results
    /// always reflect the latest books and quotes.
    private func syncSearchIndex() {
        guard let searchServices else { return }
        let currentBooks = books
        Task {
            await searchServices.syncIndex(books: currentBooks)
        }
    }

    /// A tapped search result no longer exists (deleted since the results
    /// were fetched): resync the index and re-run the search so the stale
    /// row disappears instead of silently doing nothing.
    private func refreshStaleSearchResults() {
        guard let searchServices else { return }
        HapticManager.warning()
        let currentBooks = books
        let query = searchText
        let scope = searchScope
        Task {
            await searchServices.syncIndex(books: currentBooks)
            await searchServices.searchService.searchImmediate(query, scope: scope)
        }
    }

    /// Refresh library data with pull-to-refresh
    private func refreshLibrary() async {
        isRefreshing = true
        HapticManager.light()

        // Rebuild search index from the current library contents
        if let searchServices {
            await searchServices.syncIndex(books: books)
        }

        isRefreshing = false
        HapticManager.success()
    }

    private func deleteBook(_ book: Book) {
        withAnimation {
            do {
                try BookDeletionService(modelContext: modelContext).delete(book)
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
