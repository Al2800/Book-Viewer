import SwiftUI
import UIKit

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

enum BookCoverImageCache {
    private static let cache = NSCache<NSString, UIImage>()

    static func cacheKey(bookID: UUID, thumbnailData: Data?) -> String {
        "\(bookID.uuidString)-\(thumbnailData?.count ?? 0)"
    }

    static func cachedImage(bookID: UUID, thumbnailData: Data?) -> UIImage? {
        let key = cacheKey(bookID: bookID, thumbnailData: thumbnailData) as NSString
        return cache.object(forKey: key)
    }

    static func image(bookID: UUID, thumbnailData: Data?) async -> UIImage? {
        guard let thumbnailData, !thumbnailData.isEmpty else { return nil }

        let key = cacheKey(bookID: bookID, thumbnailData: thumbnailData) as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        return await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: thumbnailData) else { return nil }
            cache.setObject(image, forKey: key)
            return image
        }.value
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

    @State private var decodedImage: UIImage?

    var body: some View {
        Group {
            if let uiImage = displayedImage {
                coverImage(uiImage)
            } else {
                placeholder
            }
        }
        .task(id: coverCacheKey) {
            decodedImage = await BookCoverImageCache.image(
                bookID: book.id,
                thumbnailData: book.coverThumbnailData
            )
        }
    }

    private var coverCacheKey: String {
        BookCoverImageCache.cacheKey(bookID: book.id, thumbnailData: book.coverThumbnailData)
    }

    private var displayedImage: UIImage? {
        decodedImage ?? BookCoverImageCache.cachedImage(
            bookID: book.id,
            thumbnailData: book.coverThumbnailData
        )
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
