import SwiftUI

struct BookCoverQuoteCountBadge: View {
    let quoteCount: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "quote.opening")
                .font(.caption2)
            Text("\(quoteCount)")
                .font(.caption2)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 4)
        .glassFloating(cornerRadius: CornerRadius.sm)
        .padding(Spacing.xs)
    }
}

struct BookCoverArtwork: View {
    enum Style {
        case grid
        case list
    }

    let book: Book
    let style: Style
    let reduceMotion: Bool

    var body: some View {
        switch style {
        case .grid:
            ThreeDimensionalBookView(
                book: book,
                width: 112,
                height: 168,
                pageBlockThickness: 8,
                isInteractive: false,
                showQuoteBadge: false,
                presentation: .card
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(2 / 3, contentMode: .fit)

        case .list:
            listThumbnail
        }
    }

    @ViewBuilder
    private var listThumbnail: some View {
        if let coverData = book.coverThumbnailData ?? book.coverFullData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                }
                .elevation(.xs)
        } else {
            let theme = ClothboundJacketTheme.forBook(book)
            RoundedRectangle(cornerRadius: CornerRadius.xs)
                .fill(theme.baseColor)
                .frame(width: 48, height: 70)
                .overlay {
                    VStack(spacing: 2) {
                        Text("✦")
                            .font(.system(size: 8))
                            .foregroundStyle(theme.foilGradient)
                        Text(book.title)
                            .font(.system(size: 8, weight: .bold, design: .serif))
                            .foregroundStyle(theme.foilGradient)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 2)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .stroke(theme.foilBorderColor.opacity(0.6), lineWidth: Stroke.hairline.width)
                }
                .elevation(.xs)
        }
    }
}

struct BookReadingStatusBadge: View {
    enum Style {
        case grid
        case list
    }

    let status: ReadingStatus
    let style: Style

    var body: some View {
        Text(label)
            .font(.caption2)
            .lineLimit(1)
            .layoutPriority(style == .grid ? 1 : 0)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch (style, status) {
        case (.grid, .wantToRead):
            return "Want"
        default:
            return status.displayName
        }
    }

    private var color: Color {
        switch status {
        case .currentlyReading: return .accent
        case .finished: return .success
        case .wantToRead: return .textSecondary
        case .abandoned: return .textTertiary
        }
    }
}

struct BookCardContextMenuItems: View {
    var onEdit: (() -> Void)?
    var onViewQuotes: (() -> Void)?
    var onShare: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        if let onEdit {
            Button {
                HapticManager.light()
                onEdit()
            } label: {
                Label("Edit Book", systemImage: "pencil")
            }
        }

        if let onViewQuotes {
            Button {
                HapticManager.light()
                onViewQuotes()
            } label: {
                Label("View Quotes", systemImage: "text.quote")
            }
        }

        if let onShare {
            Button {
                HapticManager.light()
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }

        if onDelete != nil {
            Divider()

            Button(role: .destructive) {
                HapticManager.warning()
                onDelete?()
            } label: {
                Label("Delete Book", systemImage: "trash")
            }
        }
    }
}
