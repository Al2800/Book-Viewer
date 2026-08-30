import SwiftUI

// MARK: - BookCoverCard

/// Grid card displaying a book cover with quote count badge.
/// Features Stripe-level polish: elevation, press states, haptics, and entrance animations.
struct BookCoverCard: View {

    // MARK: - Properties

    let book: Book

    /// Optional tap action for interactive cards
    var onTap: (() -> Void)?

    /// Context menu actions
    var onEdit: (() -> Void)?
    var onShare: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - State

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - Body

    var body: some View {
        Group {
            if let onTap {
                Button {
                    HapticManager.light()
                    onTap()
                } label: {
                    cardContent
                }
                .buttonStyle(BookCardButtonStyle(pressedScale: 0.96, reduceMotion: reduceMotion))
            } else {
                cardContent
            }
        }
        .if(hasContextMenu) { view in
            view.polishedContextMenu(
                menuItems: { contextMenuItems },
                preview: { BookContextMenuPreview(book: book) }
            )
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCoverCard)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                // Cover image
                BookCoverArtwork(book: book, style: .grid, reduceMotion: reduceMotion)

                if book.hasQuotes {
                    BookCoverQuoteCountBadge(quoteCount: book.quoteCount)
                }
            }

            Text(book.title)
                .font(.bookTitleSmall)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .padding(.top, Spacing.xxs)

            Text(book.author)
                .font(.authorNameSmall)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)

            cardMetadata
        }
        .padding(Spacing.sm)
        .paperCard(cornerRadius: CornerRadius.lg)
        // MARK: - Entrance Animation
        .opacity(hasAppeared ? 1.0 : 0.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.9)
        .onAppear {
            if UITestConfiguration.isUITesting || reduceMotion {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(entranceDelay)) {
                hasAppeared = true
            }
        }
    }

    @ViewBuilder
    private var cardMetadata: some View {
        if dynamicTypeSize >= .xxxLarge {
            metadataStack
        } else {
            ViewThatFits(in: .horizontal) {
                metadataRow
                metadataStack
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: Spacing.xs) {
            BookReadingStatusBadge(status: book.status, style: .grid)
            quoteCountLabel
        }
    }

    private var metadataStack: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            BookReadingStatusBadge(status: book.status, style: .grid)
            quoteCountLabel
        }
    }

    @ViewBuilder
    private var quoteCountLabel: some View {
        if book.hasQuotes {
            Text("\(book.quoteCount) quotes")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Staggered entrance delay for list animations
    private var entranceDelay: Double {
        Double.random(in: 0.0...0.15)
    }

    // MARK: - Context Menu

    /// Whether any context menu action is provided
    private var hasContextMenu: Bool {
        onEdit != nil || onShare != nil || onDelete != nil
    }

    /// Context menu items
    @ViewBuilder
    private var contextMenuItems: some View {
        if let onEdit = onEdit {
            BookCardContextMenuItems(
                onEdit: onEdit,
                onShare: onShare,
                onDelete: onDelete
            )
        } else {
            BookCardContextMenuItems(
                onShare: onShare,
                onDelete: onDelete
            )
        }
    }
}

// MARK: - BookListRow

/// List row displaying book details with cover thumbnail.
/// Features polished press state, haptics, and smooth transitions.
struct BookListRow: View {

    // MARK: - Properties

    let book: Book

    /// Optional tap action
    var onTap: (() -> Void)?

    /// Context menu actions
    var onEdit: (() -> Void)?
    var onShare: (() -> Void)?
    var onDelete: (() -> Void)?

    // MARK: - State

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - Body

    var body: some View {
        Group {
            if let onTap {
                Button {
                    HapticManager.light()
                    onTap()
                } label: {
                    rowContent
                }
                .buttonStyle(BookCardButtonStyle(pressedScale: 0.98, reduceMotion: reduceMotion))
            } else {
                rowContent
            }
        }
        .if(hasContextMenu) { view in
            view.polishedContextMenu(
                menuItems: { contextMenuItems },
                preview: { BookContextMenuPreview(book: book) }
            )
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookListRow)
    }

    private var rowContent: some View {
        HStack(spacing: Spacing.md) {
            // Small cover thumbnail
            BookCoverArtwork(book: book, style: .list, reduceMotion: reduceMotion)

            // Book details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(book.title)
                    .font(.bookTitle)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                Text(book.author)
                    .font(.authorName)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)

                listMetadata
            }

            Spacer()

            // Chevron indicator for navigation
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.md)
        .paperCard(cornerRadius: CornerRadius.lg)
        // MARK: - Entrance Animation
        .opacity(hasAppeared ? 1.0 : 0.0)
        .offset(x: hasAppeared ? 0 : -10)
        .onAppear {
            if UITestConfiguration.isUITesting || reduceMotion {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(entranceDelay)) {
                hasAppeared = true
            }
        }
    }

    @ViewBuilder
    private var listMetadata: some View {
        if dynamicTypeSize >= .xxxLarge {
            listMetadataStack
        } else {
            ViewThatFits(in: .horizontal) {
                listMetadataRow
                listMetadataStack
            }
        }
    }

    private var listMetadataRow: some View {
        HStack(spacing: Spacing.sm) {
            BookReadingStatusBadge(status: book.status, style: .list)
            listQuoteCountLabel
        }
    }

    private var listMetadataStack: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            BookReadingStatusBadge(status: book.status, style: .list)
            listQuoteCountLabel
        }
    }

    @ViewBuilder
    private var listQuoteCountLabel: some View {
        if book.hasQuotes {
            Text("\(book.quoteCount) quotes")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .contentTransition(.numericText())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Staggered entrance delay
    private var entranceDelay: Double {
        Double.random(in: 0.0...0.1)
    }

    // MARK: - Context Menu

    /// Whether any context menu action is provided
    private var hasContextMenu: Bool {
        onEdit != nil || onShare != nil || onDelete != nil
    }

    /// Context menu items
    @ViewBuilder
    private var contextMenuItems: some View {
        BookCardContextMenuItems(
            onEdit: onEdit,
            onShare: onShare,
            onDelete: onDelete
        )
    }
}

private struct BookCardButtonStyle: ButtonStyle {
    let pressedScale: CGFloat
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Book Cards") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Grid card preview
            Text("Grid Cards (Tappable)")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                BookCoverCard(
                    book: Book(title: "Atomic Habits", author: "James Clear"),
                    onTap: { print("Tapped Atomic Habits") }
                )
                BookCoverCard(
                    book: Book(title: "Deep Work", author: "Cal Newport"),
                    onTap: { print("Tapped Deep Work") }
                )
                BookCoverCard(
                    book: Book(title: "The Psychology of Money", author: "Morgan Housel"),
                    onTap: { print("Tapped Psychology of Money") }
                )
            }
            .padding()

            Divider()

            // List row preview
            Text("List Rows (Tappable)")
                .font(.headline)
            VStack(spacing: 0) {
                BookListRow(
                    book: Book(title: "Atomic Habits", author: "James Clear"),
                    onTap: { print("Row tapped") }
                )
                Divider()
                BookListRow(
                    book: Book(title: "Deep Work", author: "Cal Newport"),
                    onTap: { print("Row tapped") }
                )
            }
            .padding(.horizontal)
        }
    }
    .background(Color.backgroundPrimary)
}
