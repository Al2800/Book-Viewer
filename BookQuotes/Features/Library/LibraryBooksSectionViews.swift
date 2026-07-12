import SwiftUI

struct LibraryBooksSection: View {
    let books: [Book]
    @Binding var viewMode: LibraryViewMode
    let hasAppeared: Bool
    let reduceMotion: Bool
    let onTap: (Book) -> Void
    let onEdit: (Book) -> Void
    let onDelete: (Book) -> Void

    var body: some View {
        SectionCard(title: "Books") {
            switch viewMode {
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

    private var bookGridContent: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)],
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
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookCoverCard)
                .accessibilityLabel("\(book.title) by \(book.author)")
                .accessibilityHint("Open book details")
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                    value: hasAppeared
                )
            }
        }
    }

    private var bookListContent: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
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
                .accessibilityIdentifier(AccessibilityIdentifiers.Library.bookListRow)
                .opacity(hasAppeared ? 1 : 0)
                .offset(x: hasAppeared ? 0 : -20)
                .animation(
                    reduceMotion ? .none : .smoothSpring.delay(Double(min(index, 8)) * 0.05),
                    value: hasAppeared
                )
            }
        }
    }
}

struct LibraryViewModeControl: View {
    @Binding var viewMode: LibraryViewMode

    var body: some View {
        Picker("View", selection: $viewMode) {
            Image(systemName: LibraryViewMode.grid.systemImageName).tag(LibraryViewMode.grid)
            Image(systemName: LibraryViewMode.list.systemImageName).tag(LibraryViewMode.list)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 150)
        .accessibilityIdentifier(AccessibilityIdentifiers.Library.viewModeToggle)
    }
}
