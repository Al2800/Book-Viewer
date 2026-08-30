import SwiftUI
import SwiftData

// MARK: - ActiveBookHUDView

/// Floating Liquid Glass HUD pill showing the active reading book at the top of the viewfinder.
struct ActiveBookHUDView: View {
    let book: Book?
    let onSwitchBook: () -> Void
    var onClose: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Button(action: onSwitchBook) {
                HStack(spacing: Spacing.sm) {
                    bookThumbnail

                    VStack(alignment: .leading, spacing: 1) {
                        if let book {
                            Text(book.title)
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(book.author)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.78))
                                .lineLimit(1)
                        } else {
                            Text("No Book Selected")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("Tap to choose active book")
                                .font(.caption2)
                                .foregroundStyle(Color.gildedAccent)
                        }
                    }
                    .frame(maxWidth: 180, alignment: .leading)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.gildedAccent)
                }
                .padding(.leading, Spacing.md)
                .padding(.trailing, onClose == nil ? Spacing.md : Spacing.xs)
                .padding(.vertical, Spacing.xs)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(book != nil ? "Active Book: \(book!.title). Tap to switch" : "Select active book")

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close capture")
                .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cancelButton)
                .padding(.trailing, Spacing.xs)
            }
        }
        .background(
            Capsule()
                .fill(Color.black.opacity(0.62))
                .overlay {
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.35))
                }
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.22), lineWidth: Stroke.hairline.width)
                }
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
    }

    @ViewBuilder
    private var bookThumbnail: some View {
        if let book, let coverData = book.coverThumbnailData ?? book.coverFullData, let uiImage = UIImage(data: coverData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 24, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xs)
                    .fill(LinearGradient.spineDepth)
                    .frame(width: 24, height: 32)

                Image(systemName: "book.closed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.gildedAccent)
            }
        }
    }
}

// MARK: - ActiveBookSwitcherSheet

/// 1-tap book switcher sheet with quick ISBN scanner fallback.
struct ActiveBookSwitcherSheet: View {
    @Query(sort: \Book.dateModified, order: .reverse) private var books: [Book]
    let currentBook: Book?
    let onSelectBook: (Book) -> Void
    let onScanNewBook: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var currentlyReadingBooks: [Book] {
        books.filter { $0.status == .currentlyReading }
    }

    private var otherBooks: [Book] {
        books.filter { $0.status != .currentlyReading }
    }

    var body: some View {
        NavigationStack {
            List {
                // Add New Book Section
                Section {
                    Button {
                        dismiss()
                        onScanNewBook()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.foilAccent)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.black.opacity(0.8))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan ISBN / Add Book")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)

                                Text("Add a new title with barcode lookup")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.gildedAccent)
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }

                // Currently Reading Section
                if !currentlyReadingBooks.isEmpty {
                    Section("Currently Reading") {
                        ForEach(currentlyReadingBooks) { book in
                            bookRow(book)
                        }
                    }
                }

                // All Other Books Section
                if !otherBooks.isEmpty {
                    Section("Library") {
                        ForEach(otherBooks) { book in
                            bookRow(book)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Switch Active Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func bookRow(_ book: Book) -> some View {
        Button {
            HapticManager.selection()
            onSelectBook(book)
            dismiss()
        } label: {
            HStack(spacing: Spacing.md) {
                if let coverData = book.coverThumbnailData ?? book.coverFullData, let uiImage = UIImage(data: coverData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xs))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.xs)
                            .fill(LinearGradient.spineDepth)
                            .frame(width: 32, height: 44)

                        Image(systemName: "book.closed")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.gildedAccent)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(book.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if currentBook?.id == book.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color.gildedAccent)
                }
            }
            .padding(.vertical, Spacing.xxs)
        }
        .buttonStyle(.plain)
    }
}
