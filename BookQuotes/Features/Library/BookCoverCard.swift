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

    @State private var isPressed = false
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack(alignment: .topTrailing) {
                // Cover image
                coverImage

                if book.hasQuotes {
                    HStack(spacing: 4) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                        Text("\(book.quoteCount)")
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

            Text(book.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)

            Text(book.author)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)

            HStack(spacing: Spacing.xs) {
                statusBadge

                if book.hasQuotes {
                    Text("\(book.quoteCount) quotes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(Spacing.md)
        .paperCard(cornerRadius: CornerRadius.lg)
        // MARK: - Press State Animation
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
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
        // MARK: - Tap Gesture with Haptics
        .if(onTap != nil) { view in
            view
                .onTapGesture {
                    HapticManager.light()
                    onTap?()
                }
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    guard !hasContextMenu else { return }
                    withAnimation(.quickSpring) {
                        isPressed = pressing
                    }
                }, perform: {})
        }
        // MARK: - Context Menu
        .if(hasContextMenu) { view in
            view.polishedContextMenu(
                menuItems: { contextMenuItems },
                preview: { BookContextMenuPreview(book: book) }
            )
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCoverCard)
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
            Button {
                HapticManager.light()
                onEdit()
            } label: {
                Label("Edit Book", systemImage: "pencil")
            }
        }

        Button {
            // Navigate to view quotes (handled by caller via onTap usually)
            HapticManager.light()
        } label: {
            Label("View Quotes", systemImage: "text.quote")
        }

        if let onShare = onShare {
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

    // MARK: - Private Views

    @ViewBuilder
    private var coverImage: some View {
        if let coverData = book.coverThumbnailData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(2/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                )
        } else {
            // Placeholder cover with subtle gradient
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
                            .symbolEffect(.pulse, options: .repeating.speed(0.3), isActive: !reduceMotion)
                            .foregroundStyle(Color.textSecondary)

                        Text(book.title)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, Spacing.xs)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.quoteBorder.opacity(0.5), lineWidth: Stroke.hairline.width)
                )
        }
    }

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

    @State private var isPressed = false
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    // Status badge with animation
                    statusBadge

                    // Quote count with numeric transition
                    if book.hasQuotes {
                        Text("\(book.quoteCount) quotes")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .contentTransition(.numericText())
                    }
                }
            }

            Spacer()

            // Chevron indicator for navigation
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.md)
        .paperCard(cornerRadius: CornerRadius.lg)
        // MARK: - Press State
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
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
        // MARK: - Tap Gesture
        .if(onTap != nil) { view in
            view
                .onTapGesture {
                    HapticManager.light()
                    onTap?()
                }
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    guard !hasContextMenu else { return }
                    withAnimation(.quickSpring) {
                        isPressed = pressing
                    }
                }, perform: {})
        }
        // MARK: - Context Menu
        .if(hasContextMenu) { view in
            view.polishedContextMenu(
                menuItems: { contextMenuItems },
                preview: { BookContextMenuPreview(book: book) }
            )
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookListRow)
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
        if let onEdit = onEdit {
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

        if let onShare = onShare {
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

    // MARK: - Private Views

    @ViewBuilder
    private var coverThumbnail: some View {
        if let coverData = book.coverThumbnailData,
           let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                )
        } else {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.backgroundSecondary)
                .frame(width: 50, height: 72)
                .overlay {
                    Image(systemName: "book.closed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                )
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
