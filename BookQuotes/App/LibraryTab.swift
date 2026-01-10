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
                    onQuoteTap: { quoteId in
                        if let quote = fetchQuote(id: quoteId) {
                            router.navigate(to: quote)
                        }
                    },
                    onBookTap: { bookId in
                        if let book = fetchBook(id: bookId) {
                            router.navigate(to: book)
                        }
                    }
                )
            } else if books.isEmpty {
                EmptyLibraryView()
            } else {
                // Normal library view
                switch viewMode {
                case .grid:
                    bookGrid
                case .list:
                    bookList
                }
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)

                // Add book button
                Button {
                    // TODO: Navigate to add book flow
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            initializeSearchService()
        }
    }

    // MARK: - Grid View

    private var bookGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)],
                spacing: Spacing.lg
            ) {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookCoverCard(book: book)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - List View

    private var bookList: some View {
        List(books) { book in
            NavigationLink(value: book) {
                BookListRow(book: book)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Private Methods

    private func initializeSearchService() {
        guard searchService == nil else { return }
        do {
            searchService = try SearchService()
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
}

/// Empty state for library
struct EmptyLibraryView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Books Yet", systemImage: "books.vertical")
        } description: {
            Text("Capture your first book cover to start building your library.")
        } actions: {
            // Will be wired to capture tab later
        }
    }
}




#Preview {
    LibraryTab()
        .modelContainer(.preview)
}
