import SwiftUI

// MARK: - LibraryBookshelfView

/// 3D horizontal interactive bookshelf displaying currently reading books.
/// Features tactile spine depth, realistic shadow projection, and a wooden shelf ledge.
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
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .bottom, spacing: Spacing.lg) {
                    ForEach(currentlyReadingBooks) { book in
                        BookshelfItemView(book: book) {
                            HapticManager.light()
                            onSelectBook(book)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xs)
            }

            // Tactile wooden shelf ledge
            BookshelfLedge()
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

/// Single standing book item on the 3D shelf with spine shading.
struct BookshelfItemView: View {
    let book: Book
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.xs) {
                // Book Cover with 3D Spine and realistic shadow
                ZStack(alignment: .leading) {
                    BookCoverArtwork(book: book, style: .grid, reduceMotion: reduceMotion)
                        .frame(width: 90, height: 135)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        .overlay {
                            // 3D book spine depth shader
                            LinearGradient.spineDepth
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.white.opacity(0.15), lineWidth: Stroke.hairline.width)
                        }

                    // Gold foil badge for quote count
                    if book.hasQuotes {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(book.quoteCount)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.black.opacity(0.85))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(LinearGradient.foilAccent)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.black.opacity(0.15), radius: 1, y: 1)
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
                .elevation(.md)

                // Title label
                Text(book.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .frame(width: 90)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .frame(width: 90)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.author), \(book.quoteCount) quotes")
        .accessibilityHint("Open book details")
    }
}

// MARK: - BookshelfLedge

/// Tactile shelf ledge underneath standing books with wood-like depth.
struct BookshelfLedge: View {
    var body: some View {
        VStack(spacing: 0) {
            // Shelf top surface highlight
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.80, blue: 0.72).opacity(0.6),
                            Color(red: 0.70, green: 0.65, blue: 0.58).opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 3)

            // Shelf front bevel ledge
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.48, blue: 0.40).opacity(0.8),
                            Color(red: 0.38, green: 0.32, blue: 0.26).opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 6)
                .shadow(color: Color.black.opacity(0.15), radius: 3, y: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
    }
}
