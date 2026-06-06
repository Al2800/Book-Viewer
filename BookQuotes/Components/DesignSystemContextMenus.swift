import SwiftUI

// MARK: - Context Menu Animations

/// View modifier that adds a polished context menu with haptic feedback and lift animation.
/// Provides a custom preview that elevates on long press before the menu appears.
struct PolishedContextMenuModifier<MenuItems: View, Preview: View>: ViewModifier {
    let menuItems: () -> MenuItems
    let preview: () -> Preview
    let onPresent: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPresenting = false

    init(
        @ViewBuilder menuItems: @escaping () -> MenuItems,
        @ViewBuilder preview: @escaping () -> Preview,
        onPresent: (() -> Void)? = nil
    ) {
        self.menuItems = menuItems
        self.preview = preview
        self.onPresent = onPresent
    }

    func body(content: Content) -> some View {
        content
            .contextMenu(menuItems: menuItems, preview: preview)
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                if isPressing && !isPresenting {
                    // Haptic as menu begins to appear
                    HapticManager.medium()
                    onPresent?()
                    isPresenting = true
                }
                if !isPressing {
                    isPresenting = false
                }
            }, perform: {})
    }
}

/// Simplified context menu modifier when preview matches content.
struct SimpleContextMenuModifier<MenuItems: View>: ViewModifier {
    let menuItems: () -> MenuItems

    func body(content: Content) -> some View {
        content
            .contextMenu(menuItems: menuItems)
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                if isPressing {
                    HapticManager.medium()
                }
            }, perform: {})
    }
}

extension View {
    /// Add a polished context menu with custom preview and haptic feedback.
    /// - Parameters:
    ///   - menuItems: The menu content shown on long press
    ///   - preview: Custom preview view shown during context menu presentation
    ///   - onPresent: Optional callback when context menu begins presenting
    func polishedContextMenu<MenuItems: View, Preview: View>(
        @ViewBuilder menuItems: @escaping () -> MenuItems,
        @ViewBuilder preview: @escaping () -> Preview,
        onPresent: (() -> Void)? = nil
    ) -> some View {
        modifier(PolishedContextMenuModifier(
            menuItems: menuItems,
            preview: preview,
            onPresent: onPresent
        ))
    }

    /// Add a polished context menu with haptic feedback (uses content as preview).
    /// - Parameter menuItems: The menu content shown on long press
    func polishedContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: @escaping () -> MenuItems
    ) -> some View {
        modifier(SimpleContextMenuModifier(menuItems: menuItems))
    }
}

// MARK: - Context Menu Preview Wrappers

/// Preview wrapper that adds elevation and polish for context menu previews.
struct ContextMenuPreview<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(cornerRadius: CGFloat = CornerRadius.md, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .elevation(.lg, colorScheme: colorScheme)
    }
}

/// Quote context menu preview with styled container
struct QuoteContextMenuPreview: View {
    let quote: Quote
    let showBookInfo: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(quote: Quote, showBookInfo: Bool = false) {
        self.quote = quote
        self.showBookInfo = showBookInfo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(quote.text)
                .font(.quoteBody)
                .lineLimit(6)
                .foregroundStyle(Color.textPrimary)

            if showBookInfo, let book = quote.book {
                Divider()
                HStack {
                    Text(book.title)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("by \(book.author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if quote.isFavorite {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Favorite")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: 300)
        .background(Color.quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder, lineWidth: 1)
        }
        .elevation(.lg, colorScheme: colorScheme)
    }
}

/// Book context menu preview with cover and info
struct BookContextMenuPreview: View {
    let book: Book

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Cover image
            if let coverData = book.coverThumbnailData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.backgroundSecondary)
                    .frame(width: 60, height: 90)
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if book.hasQuotes {
                    Text("\(book.quoteCount) quotes")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(book.status.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accent.opacity(0.15))
                    .foregroundStyle(Color.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.lg, colorScheme: colorScheme)
    }
}
