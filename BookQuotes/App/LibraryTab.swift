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

/// Main library view showing books grid
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    @State private var searchText = ""

    var body: some View {
        Group {
            if books.isEmpty {
                EmptyLibraryView()
            } else {
                BookGridView(books: filteredBooks)
            }
        }
        .navigationTitle("Library")
        .searchable(text: $searchText, prompt: "Search books...")
    }

    private var filteredBooks: [Book] {
        guard !searchText.isEmpty else { return books }
        return books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
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

/// Grid display of books
struct BookGridView: View {
    let books: [Book]

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.lg) {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookGridItem(book: book)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

/// Individual book item in grid
struct BookGridItem: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Cover image or placeholder
            Group {
                if let imageData = book.coverThumbnailData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.backgroundSecondary)
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay {
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

            // Title and author
            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)

            Text(book.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

/// Book detail view placeholder
struct BookDetailView: View {
    let book: Book

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(book.title)
                    .font(.bookTitle)
                Text("by \(book.author)")
                    .font(.authorName)
                    .foregroundStyle(.secondary)

                if book.quotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Quotes Yet", systemImage: "quote.opening")
                    } description: {
                        Text("Capture some pages to extract quotes from this book.")
                    }
                } else {
                    Text("Quotes")
                        .font(.sectionHeader)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    ForEach(book.quotes) { quote in
                        NavigationLink(value: quote) {
                            QuoteListItem(quote: quote)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Quote list item
struct QuoteListItem: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(quote.text)
                .font(.quoteBody)
                .lineLimit(3)

            if let page = quote.pageNumber {
                Text("p. \(page)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

/// Quote detail view placeholder
struct QuoteDetailView: View {
    let quote: Quote

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(quote.text)
                    .quoteTextStyle()

                if let marginNote = quote.marginNote {
                    HStack {
                        Image(systemName: "note.text")
                        Text(marginNote)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Divider()

                // Metadata
                LabeledContent("Page", value: quote.pageNumber.map { "\($0)" } ?? "—")
                LabeledContent("Marking", value: quote.markingDisplayName)

                if let confidence = quote.confidence {
                    LabeledContent("Confidence", value: "\(Int(confidence * 100))%")
                }
            }
            .padding()
        }
        .navigationTitle("Quote")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LibraryTab()
        .modelContainer(.preview)
}
