import SwiftUI

// MARK: - BookCoverCard

/// Grid card displaying a book cover with quote count badge.
struct BookCoverCard: View {

    // MARK: - Properties

    let book: Book

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Cover image
            coverImage

            // Quote count badge
            if book.hasQuotes {
                Text("\(book.quoteCount) quotes")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCoverCard)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var coverImage: some View {
        if let coverData = book.coverThumbnailData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(2/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        } else {
            // Placeholder cover
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.backgroundSecondary)
                .aspectRatio(2/3, contentMode: .fit)
                .overlay {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "book.closed")
                            .font(.title)

                        Text(book.title)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, Spacing.xs)
                    }
                    .foregroundStyle(.secondary)
                }
        }
    }
}

// MARK: - BookListRow

/// List row displaying book details with cover thumbnail.
struct BookListRow: View {

    // MARK: - Properties

    let book: Book

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Small cover thumbnail
            coverThumbnail

            // Book details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(book.title)
                    .font(.bookTitle)
                    .lineLimit(2)

                Text(book.author)
                    .font(.authorName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    // Status badge
                    statusBadge

                    // Quote count
                    if book.hasQuotes {
                        Text("\(book.quoteCount) quotes")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookListRow)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var coverThumbnail: some View {
        if let coverData = book.coverThumbnailData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm - 2))
        } else {
            RoundedRectangle(cornerRadius: CornerRadius.sm - 2)
                .fill(Color.backgroundSecondary)
                .frame(width: 44, height: 66)
                .overlay {
                    Image(systemName: "book.closed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(book.status.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch book.status {
        case .currentlyReading: return .accent
        case .finished: return .success
        case .wantToRead: return .textSecondary
        case .abandoned: return .textTertiary
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        // Grid card preview
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
            BookCoverCard(book: Book(title: "Atomic Habits", author: "James Clear"))
            BookCoverCard(book: Book(title: "Deep Work", author: "Cal Newport"))
        }
        .padding()

        Divider()

        // List row preview
        List {
            BookListRow(book: Book(title: "Atomic Habits", author: "James Clear"))
            BookListRow(book: Book(title: "Deep Work", author: "Cal Newport"))
        }
    }
}
