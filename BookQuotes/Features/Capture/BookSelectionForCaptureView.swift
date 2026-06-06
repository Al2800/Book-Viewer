import SwiftData
import SwiftUI

/// Library-backed book picker used before single-page and batch quote capture.
struct BookSelectionForCaptureView: View {
    let onSelectBook: (Book) -> Void
    let onAddNewBook: () -> Void
    let onCancel: () -> Void

    @Query(sort: \Book.dateLastQuoteAdded, order: .reverse)
    private var books: [Book]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if books.isEmpty {
                    emptyState
                } else {
                    librarySection
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Select Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        VStack(spacing: Spacing.lg) {
            CaptureSectionCard(title: "Library") {
                AddBookLibraryRow(action: onAddNewBook)

                ForEach(books) { book in
                    CaptureBookRow(book: book) {
                        onSelectBook(book)
                    }
                }
            }

            CaptureSectionCard(title: "Capture Notes") {
                CaptureHintRow(
                    systemImage: "text.quote",
                    title: "Single capture",
                    subtitle: "Best when you want to review and save one marked page immediately."
                )

                CaptureHintRow(
                    systemImage: "square.stack.3d.up.fill",
                    title: "Batch capture",
                    subtitle: "Best when you are moving through several pages from the same book."
                )
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        CaptureSectionCard(title: "Library") {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.backgroundSecondary)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Circle()
                                    .stroke(
                                        Color.quoteBorder.opacity(0.6),
                                        lineWidth: Stroke.hairline.width
                                    )
                            }

                        Image(systemName: "books.vertical")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Books Yet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)

                        Text("Add a book first so quote capture has somewhere to save your passages.")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Button(action: onAddNewBook) {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.backgroundSecondary)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            Color.quoteBorder.opacity(0.6),
                                            lineWidth: Stroke.hairline.width
                                        )
                                }

                            Image(systemName: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.accent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Your First Book")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.textPrimary)

                            Text("Scan the cover or ISBN to start a capture session.")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CaptureBookRow: View {
    let book: Book
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                captureCover

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)

                    Text(bookCaptureSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.bookSelectionCard)
    }

    private var bookCaptureSubtitle: String {
        if book.quoteCount == 0 {
            return "Ready for first capture"
        }

        let quoteLabel = book.quoteCount == 1 ? "quote" : "quotes"
        return "\(book.quoteCount) \(quoteLabel) saved"
    }

    @ViewBuilder
    private var captureCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.backgroundSecondary)

            if let coverData = book.coverThumbnailData ?? book.coverFullData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "book.closed.fill")
                    .font(.headline)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(width: 44, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
        }
    }
}

private struct AddBookLibraryRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                        }

                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add New Book")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text("Scan a cover or ISBN before capturing quotes.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Legacy alias retained for preview and older call-site terminology.
struct BookGridItem: View {
    let book: Book
    let action: () -> Void

    var body: some View {
        CaptureBookRow(book: book, action: action)
    }
}

/// Legacy alias retained for preview and older call-site terminology.
struct AddBookGridItem: View {
    let action: () -> Void

    var body: some View {
        AddBookLibraryRow(action: action)
    }
}

#Preview("Book Selection") {
    Group {
        if let container = ModelContainer.preview {
            BookSelectionForCaptureView(
                onSelectBook: { _ in },
                onAddNewBook: {},
                onCancel: {}
            )
            .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
