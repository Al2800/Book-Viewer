import SwiftUI

// MARK: - BookSearchResultRow

/// Row displaying a book search result with highlighted matches.
struct BookSearchResultRow: View {

    // MARK: - Properties

    let result: SearchBookResult
    let query: String

    /// Optional Book model for additional context
    var book: Book?

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Cover image
            coverImage

            // Book details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title with FTS5 highlighting
                Text(result.highlightedTitle)
                    .font(.bookTitle)
                    .lineLimit(2)

                // Author with FTS5 highlighting
                Text(result.highlightedAuthor)
                    .font(.authorName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Quote count
                if let book = book {
                    Text("\(book.quoteCount) quotes")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var coverImage: some View {
        if let book = book,
           let coverData = book.coverThumbnailData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        } else {
            // Placeholder
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.backgroundSecondary)
                .frame(width: 50, height: 70)
                .overlay {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.secondary)
                }
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        BookSearchResultRow(
            result: SearchBookResult(
                bookId: UUID(),
                titleSnippet: "<mark>Atomic</mark> Habits",
                authorSnippet: "James Clear",
                rank: 1.0
            ),
            query: "atomic"
        )

        BookSearchResultRow(
            result: SearchBookResult(
                bookId: UUID(),
                titleSnippet: "Deep Work",
                authorSnippet: "Cal <mark>Newport</mark>",
                rank: 0.9
            ),
            query: "newport"
        )
    }
}
