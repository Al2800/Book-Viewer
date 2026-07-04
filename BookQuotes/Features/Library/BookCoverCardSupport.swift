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
        if let coverData = book.coverThumbnailData,
           let uiImage = UIImage(data: coverData) {
            coverImage(uiImage)
        } else {
            placeholder
        }
    }

    private func coverImage(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(style == .grid ? 2/3 : nil, contentMode: .fill)
            .frame(width: style == .list ? 50 : nil, height: style == .list ? 72 : nil)
            .spineDetail(cornerRadius: cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
            )
    }

    @ViewBuilder
    private var placeholder: some View {
        switch style {
        case .grid:
            gridPlaceholder
        case .list:
            listPlaceholder
        }
    }

    private var gridPlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(
                LinearGradient(
                    colors: [Color.backgroundSecondary, Color.backgroundTertiary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(2/3, contentMode: .fit)
            .overlay {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "book.closed")
                        .font(.title)
                        .foregroundStyle(Color.textSecondary)

                    Text(book.title)
                        .font(.system(.caption2, design: .serif))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, Spacing.xs)
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .spineDetail(cornerRadius: CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.quoteBorder.opacity(0.5), lineWidth: Stroke.hairline.width)
            )
    }

    private var listPlaceholder: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm)
            .fill(Color.backgroundSecondary)
            .frame(width: 50, height: 72)
            .overlay {
                Image(systemName: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .spineDetail(cornerRadius: CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
            )
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .grid: return CornerRadius.md
        case .list: return CornerRadius.sm
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
            .minimumScaleFactor(style == .grid ? 0.6 : 0.75)
            .allowsTightening(true)
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

        Button {
            HapticManager.light()
        } label: {
            Label("View Quotes", systemImage: "text.quote")
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
