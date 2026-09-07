import SwiftUI

/// Nonempty shelves in reading order; every model status remains discoverable.
struct LibraryShelfGroup: Identifiable {
    let status: ReadingStatus
    let books: [Book]
    var id: ReadingStatus { status }

    static func groups(for books: [Book]) -> [LibraryShelfGroup] {
        let preferred: [ReadingStatus] = [.currentlyReading, .finished, .wantToRead]
        let order = preferred + ReadingStatus.allCases.filter { !preferred.contains($0) }
        return order.compactMap { status in
            let matching = books.filter { $0.status == status }
            return matching.isEmpty ? nil : LibraryShelfGroup(status: status, books: matching)
        }
    }
}

struct LibraryBooksSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let books: [Book]
    @Binding var viewMode: LibraryViewMode
    let hasAppeared: Bool
    let reduceMotion: Bool
    let onTap: (Book) -> Void
    let onEdit: (Book) -> Void
    let onDelete: (Book) -> Void

    var body: some View {
        Group {
            switch viewMode {
            case .shelves:
                bookShelvesContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            case .grid:
                bookGridContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            case .list:
                bookListContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            }
        }
    }

    private var bookShelvesContent: some View {
        VStack(spacing: Spacing.xl) {
            ForEach(LibraryShelfGroup.groups(for: books)) { group in
                shelfTier(title: group.status.displayName, icon: group.status.systemImage, books: group.books)
            }
        }
    }

    private func shelfTier(title: String, icon: String, books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.gildedAccent)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)

                Spacer()

                Text("\(books.count)")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.xs)

            ZStack(alignment: .bottom) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .bottom, spacing: Spacing.md) {
                        ForEach(books) { book in
                            BookshelfItemView(book: book) {
                                HapticManager.light()
                                onTap(book)
                            }
                            .accessibilityIdentifier("library_shelf_book")
                            .contextMenu {
                                Button("Edit Book", systemImage: "pencil") { onEdit(book) }
                                Button("Delete Book", systemImage: "trash", role: .destructive) { onDelete(book) }
                            }
                            .accessibilityAction(named: "Edit Book") { onEdit(book) }
                            .accessibilityAction(named: "Delete Book") { onDelete(book) }
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, 6)
                }

                BookshelfLedge()
                    .padding(.bottom, BookshelfItemView.captionReserve)
            }
        }
        .padding(Spacing.sm)
        .background(Color.warmVellum.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var bookGridContent: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: Spacing.lg
        ) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                BookCoverCard(
                    book: book,
                    onTap: {
                        onTap(book)
                    },
                    onEdit: {
                        onEdit(book)
                    },
                    onDelete: {
                        onDelete(book)
                    }
                )
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCoverCard)
                .accessibilityLabel("\(book.title) by \(book.author)")
                .accessibilityHint("Open book details")
                .accessibilityAddTraits(.isButton)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                    value: hasAppeared
                )
            }
        }
    }

    private var gridColumns: [GridItem] {
        if dynamicTypeSize >= .xxxLarge {
            return [GridItem(.flexible(), spacing: Spacing.md)]
        }

        return [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: Spacing.md)]
    }

    private var bookListContent: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(books) { book in
                BookListRow(
                    book: book,
                    onTap: {
                        onTap(book)
                    },
                    onEdit: {
                        onEdit(book)
                    },
                    onDelete: {
                        onDelete(book)
                    }
                )
                .accessibilityLabel("\(book.title) by \(book.author)")
                .accessibilityHint("Open book details")
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookListRow)
                .accessibilityAddTraits(.isButton)

            }
        }
    }
}

struct LibraryViewModeControl: View {
    @Binding var viewMode: LibraryViewMode

    var body: some View {
        Picker("View", selection: $viewMode) {
            Image(systemName: LibraryViewMode.shelves.systemImageName).tag(LibraryViewMode.shelves)
            Image(systemName: LibraryViewMode.grid.systemImageName).tag(LibraryViewMode.grid)
            Image(systemName: LibraryViewMode.list.systemImageName).tag(LibraryViewMode.list)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 180)
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.viewModeToggle)
    }
}
