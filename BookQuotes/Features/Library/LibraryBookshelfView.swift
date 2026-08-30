import SwiftUI

// MARK: - LibraryBookshelfView

/// 3D horizontal interactive bookshelf displaying currently reading books.
/// Features realistic 3D standing books, tactile spine depth, and a rich wooden shelf ledge.
struct LibraryBookshelfView: View {

    // MARK: - Properties

    let books: [Book]
    var onSelectBook: (Book) -> Void
    var onAddBook: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed Properties

    private var currentlyReadingBooks: [Book] {
        let reading = books.filter { $0.status == .currentlyReading }
        return reading.isEmpty ? Array(books.prefix(5)) : reading
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            header

            if currentlyReadingBooks.isEmpty {
                emptyShelfCard
            } else {
                bookshelfContent
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "books.vertical.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)
                Text("Currently Reading")
                    .sectionHeaderStyle()
            }

            Spacer()

            if !currentlyReadingBooks.isEmpty {
                Text("\(currentlyReadingBooks.count) \(currentlyReadingBooks.count == 1 ? "book" : "books")")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    // MARK: - Bookshelf Content

    private var bookshelfContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: Spacing.md) {
                    ForEach(currentlyReadingBooks) { book in
                        BookshelfItemView(book: book) {
                            HapticManager.light()
                            onSelectBook(book)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, 4)
            }

            BookshelfLedge()
                .padding(.bottom, BookshelfItemView.captionReserve)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Empty Shelf

    private var emptyShelfCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "book.closed")
                .font(.title2)
                .foregroundStyle(Color.gildedAccent)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("No active reading session")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textPrimary)

                Text("Start a book to track quotes and notes")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if let onAddBook {
                Button {
                    HapticManager.light()
                    onAddBook()
                } label: {
                    Text("Start")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.brand)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Spacing.md)
        .paperCard()
    }
}

// MARK: - BookshelfItemView

/// Single standing book item on the 3D shelf with 3D perspective projection.
struct BookshelfItemView: View {
    static let captionReserve: CGFloat = 40

    let book: Book
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ThreeDimensionalBookView(
                    book: book,
                    width: 92,
                    height: 138,
                    pageBlockThickness: 10,
                    isInteractive: false,
                    showQuoteBadge: true,
                    presentation: .shelf
                )

                Color.clear
                    .frame(height: 11)

                VStack(spacing: 2) {
                    Text(book.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text(book.author)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                .frame(width: 110, height: Self.captionReserve - 4, alignment: .top)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.author), \(book.quoteCount) quotes")
        .accessibilityHint("Open book details")
    }
}

// MARK: - BookshelfLedge

/// Tactile shelf ledge underneath standing books with rich oak/mahogany depth.
struct BookshelfLedge: View {
    var body: some View {
        VStack(spacing: 0) {
            // Shelf top surface highlight reflection
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.90, green: 0.85, blue: 0.77).opacity(0.8),
                            Color(red: 0.75, green: 0.68, blue: 0.58).opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 3.5)

            // Shelf front bevel ledge
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.52, green: 0.42, blue: 0.32),
                            Color(red: 0.36, green: 0.28, blue: 0.20),
                            Color(red: 0.26, green: 0.20, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(height: 1)
                }
                .shadow(color: Color.black.opacity(0.22), radius: 4, y: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
    }
}
