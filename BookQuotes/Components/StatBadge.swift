import SwiftUI

// MARK: - StatBadge

/// Compact badge displaying a labeled statistic.
struct StatBadge: View {

    // MARK: - Properties

    let label: String
    let value: String

    var icon: String?
    var color: Color = .secondary

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.backgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }
        )
    }
}

// MARK: - BookHeaderView

/// Header showing book cover and metadata.
struct BookHeaderView: View {

    // MARK: - Properties

    let book: Book

    /// Whether to show full metadata or compact version
    var style: Style = .default

    enum Style {
        case `default`  // Cover + full metadata
        case compact    // Inline cover + title/author
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .default:
            defaultHeader
        case .compact:
            compactHeader
        }
    }

    // MARK: - Default Header

    private var defaultHeader: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Cover image
            coverImage

            // Book info
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(book.title)
                    .font(.bookTitleLarge)
                    .lineLimit(3)
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.bookTitle)

                Text(book.author)
                    .font(.authorName)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.bookAuthor)

                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }

                // Status badge
                statusBadge
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        HStack(spacing: Spacing.md) {
            // Small cover
            smallCoverImage

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(book.title)
                    .font(.bookTitle)
                    .lineLimit(1)
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.bookTitle)

                Text(book.author)
                    .font(.authorName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.bookAuthor)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .paperCard(cornerRadius: CornerRadius.md)
    }

    // MARK: - Cover Images

    @ViewBuilder
    private var coverImage: some View {
        ThreeDimensionalBookView(
            book: book,
            width: 88,
            height: 132,
            pageBlockThickness: 10,
            isInteractive: true,
            showQuoteBadge: false,
            presentation: .hero
        )
        .frame(width: 104, height: 140, alignment: .bottomLeading)
        .clipped()
    }

    @ViewBuilder
    private var smallCoverImage: some View {
        if let coverData = book.coverThumbnailData ?? book.coverFullData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                )
        } else {
            let theme = ClothboundJacketTheme.forBook(book)
            RoundedRectangle(cornerRadius: CornerRadius.xs)
                .fill(theme.baseColor)
                .frame(width: 44, height: 66)
                .overlay {
                    VStack(spacing: 2) {
                        Text("✦")
                            .font(.system(size: 6))
                            .foregroundStyle(theme.foilGradient)
                        Text(book.title)
                            .font(.system(size: 7, weight: .bold, design: .serif))
                            .foregroundStyle(theme.foilGradient)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 2)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .stroke(theme.foilBorderColor.opacity(0.6), lineWidth: Stroke.hairline.width)
                )
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Text(book.status.displayName)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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
    VStack(spacing: 24) {
        Text("Stat Badges").font(.headline)
        HStack {
            StatBadge(label: "Quotes", value: "42", icon: "quote.opening")
            StatBadge(label: "Pages", value: "12", icon: "doc")
        }

        Divider()

        Text("Book Header - Default").font(.headline)
        BookHeaderView(book: Book(title: "Atomic Habits", author: "James Clear"))

        Divider()

        Text("Book Header - Compact").font(.headline)
        BookHeaderView(
            book: Book(title: "Atomic Habits", author: "James Clear"),
            style: .compact
        )
    }
    .padding()
}
