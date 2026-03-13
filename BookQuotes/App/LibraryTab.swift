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

    @AppStorage("libraryViewMode") private var viewMode: ViewMode = .grid
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .all
    @State private var isSearchActive = false
    @State private var searchService: SearchService?
    @State private var suggestionsService: SearchSuggestionsService?
    @State private var bookToDelete: Book?
    @State private var bookToEdit: Book?
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
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
        .sheet(isPresented: $showEditSheet) {
            if let book = bookToEdit {
                BookEditView(mode: .edit(book))
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if isSearchActive && !searchText.isEmpty {
            searchResults
        } else if books.isEmpty {
            EmptyLibraryView(onAddBook: { showAddBookSheet = true })
        } else {
            libraryContent
        }
    }

    private var searchResults: some View {
        Group {
            if let service = searchService {
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

                librarySectionCard(title: "Browse") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        LibraryControlRow(
                            icon: viewMode == .grid ? "square.grid.2x2" : "list.bullet",
                            title: "Library View",
                            subtitle: "Switch between cover cards and a compact reading list",
                            trailing: {
                                viewModeControl
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

                librarySectionCard(title: "Books") {
                    switch viewMode {
                    case .grid:
                        bookGridContent
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                    case .list:
                        bookListContent
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            ))
                    }
                }
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

    @ViewBuilder
    private var viewModeControl: some View {
        Picker("View", selection: $viewMode) {
            Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
            Image(systemName: "list.bullet").tag(ViewMode.list)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 150)
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.viewModeToggle)
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

    // MARK: - Grid View

    private var bookGridContent: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)],
            spacing: Spacing.lg
        ) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                BookCoverCard(
                    book: book,
                    onTap: {
                        router.navigate(to: book)
                    },
                    onEdit: {
                        bookToEdit = book
                        showEditSheet = true
                    },
                    onDelete: {
                        bookToDelete = book
                        showDeleteConfirmation = true
                    }
                )
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCoverCard)
                .accessibilityLabel("\(book.title) by \(book.author)")
                .accessibilityHint("Open book details")
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                    value: hasAppeared
                )
            }
        }
    }

    // MARK: - List View

    private var bookListContent: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                BookListRow(
                    book: book,
                    onTap: {
                        router.navigate(to: book)
                    },
                    onEdit: {
                        bookToEdit = book
                        showEditSheet = true
                    },
                    onDelete: {
                        bookToDelete = book
                        showDeleteConfirmation = true
                    }
                )
                .accessibilityLabel("\(book.title) by \(book.author)")
                .accessibilityHint("Open book details")
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookListRow)
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -20)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                    value: hasAppeared
                )
            }
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
        ScrollView {
            VStack(spacing: Spacing.lg) {
                LibrarySummaryCard(bookCount: 0, quoteCount: 0, viewMode: .grid)

                LibrarySectionCard(title: "Library") {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.backgroundSecondary)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Circle()
                                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                                }

                            Image(systemName: "books.vertical")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Books Yet")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)

                            Text("Add your first book to start building a searchable quote library.")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }

                    Button {
                        HapticManager.light()
                        onAddBook?()
                    } label: {
                        LibraryActionRow(
                            icon: "plus",
                            title: "Add Your First Book",
                            subtitle: "Create a book entry before capturing or importing quotes"
                        )
                    }
                    .buttonStyle(.plain)
                }

                LibrarySectionCard(title: "What You Can Do") {
                    LibraryInfoRow(
                        icon: "books.vertical",
                        title: "Organize by book",
                        subtitle: "Keep quotes grouped by title, author, and reading status."
                    )

                    LibraryInfoRow(
                        icon: "magnifyingglass",
                        title: "Search everything",
                        subtitle: "Find books and saved quotes from one place."
                    )

                    LibraryInfoRow(
                        icon: "square.and.arrow.up",
                        title: "Export later",
                        subtitle: "Share your library when you are ready."
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.emptyState)
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

private extension LibraryView {
    func librarySectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        LibrarySectionCard(title: title) {
            content()
        }
    }
}

private struct LibrarySectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: Spacing.sm) {
                content
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

private struct LibrarySummaryCard: View {
    let bookCount: Int
    let quoteCount: Int
    let viewMode: LibraryView.ViewMode

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Library")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text("Browse your books, reopen saved quotes, and switch between a cover wall and a reading list without leaving the tab.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) {
                    summaryPills
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    summaryPills
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .paperCard()
    }

    @ViewBuilder
    private var summaryPills: some View {
        LibrarySummaryPill(
            systemImage: "books.vertical",
            text: "\(bookCount) \(bookCount == 1 ? "Book" : "Books")"
        )
        LibrarySummaryPill(
            systemImage: "text.quote",
            text: "\(quoteCount) \(quoteCount == 1 ? "Quote" : "Quotes")"
        )
        LibrarySummaryPill(
            systemImage: viewMode == .grid ? "square.grid.2x2" : "list.bullet",
            text: viewMode == .grid ? "Grid View" : "List View"
        )
    }
}

private struct LibrarySummaryPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.backgroundSecondary)
        )
        .overlay {
            Capsule()
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        }
    }
}

private struct LibraryControlRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: Trailing

    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            iconCircle

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            trailing
        }
    }

    private var iconCircle: some View {
        ZStack {
            Circle()
                .fill(Color.backgroundSecondary)
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }

            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

private struct LibraryActionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle()
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .contentShape(Rectangle())
    }
}

private struct LibraryInfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle()
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }

                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
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
