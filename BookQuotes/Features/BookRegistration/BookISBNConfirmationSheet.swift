import SwiftUI
import SwiftData

// MARK: - BookISBNConfirmationSheet

/// Sheet displayed after ISBN barcode scan to confirm and edit book metadata.
/// Shows cover image, editable title/author, and read-only ISBN/publisher.
struct BookISBNConfirmationSheet: View {
    // MARK: - Properties

    let metadata: BookMetadata
    let onConfirm: (Book) -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Editable State

    @State private var title: String
    @State private var author: String
    @State private var subtitle: String
    @State private var publisher: String
    @State private var pageCount: String
    @State private var status: ReadingStatus = .wantToRead

    // MARK: - Cover Image State

    @State private var coverImageData: Data?
    @State private var isLoadingCover = false
    @State private var coverLoadError: String?

    // MARK: - Validation State

    @State private var titleShakeTrigger = 0
    @State private var authorShakeTrigger = 0

    // MARK: - Initialization

    init(
        metadata: BookMetadata,
        onConfirm: @escaping (Book) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.metadata = metadata
        self.onConfirm = onConfirm
        self.onCancel = onCancel

        // Initialize editable state from metadata
        _title = State(initialValue: metadata.title)
        _author = State(initialValue: metadata.authorsFormatted)
        _subtitle = State(initialValue: metadata.subtitle ?? "")
        _publisher = State(initialValue: metadata.publisher ?? "")
        _pageCount = State(initialValue: metadata.pageCount.map { String($0) } ?? "")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    coverSection
                    detailsSection
                    metadataSection
                    statusSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.backgroundPrimary)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Confirm Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Book") {
                        validateAndSave()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await loadCoverImage()
            }
        }
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.sectionHeader)
                    .foregroundStyle(Color.textSecondary)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }

            content()
        }
        .padding(Spacing.lg)
        .paperCard()
    }

    // MARK: - Sections

    @ViewBuilder
    private var coverSection: some View {
        sectionCard(title: "Cover") {
            HStack {
                Spacer()
                coverImageView
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var coverImageView: some View {
        Group {
            if isLoadingCover {
                ProgressView()
                    .frame(width: 140, height: 210)
            } else if let data = coverImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 140, maxHeight: 210)
            } else {
                // Placeholder when no cover available
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.backgroundSecondary)
                    .frame(width: 140, height: 210)
                    .overlay {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            if let error = coverLoadError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                    }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.backgroundSecondary)
                .overlay {
                    LinearGradient.cardHighlight
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.quoteBorder.opacity(0.7), lineWidth: Stroke.hairline.width)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.sm)
    }

    @ViewBuilder
    private var detailsSection: some View {
        sectionCard(title: "Book Details") {
            VStack(spacing: Spacing.md) {
                TextField("Title", text: $title)
                    .textContentType(.name)
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .shake(trigger: titleShakeTrigger)

                TextField("Author", text: $author)
                    .textContentType(.name)
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .shake(trigger: authorShakeTrigger)

                TextField("Subtitle (optional)", text: $subtitle)
                    .textFieldStyle(.plain)
                    .fieldChrome()
            }
        }
    }

    private var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isAuthorValid: Bool {
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func validateAndSave() {
        var hasError = false

        if !isTitleValid {
            titleShakeTrigger += 1
            hasError = true
        }

        if !isAuthorValid {
            authorShakeTrigger += 1
            hasError = true
        }

        if hasError {
            HapticManager.error()
            return
        }

        confirmAndSave()
    }

    @ViewBuilder
    private var metadataSection: some View {
        sectionCard(title: "From Database") {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let isbn = metadata.bestISBN {
                    metadataRow(title: "ISBN", value: ISBNValidator.format(isbn))
                }

                if !publisher.isEmpty {
                    metadataRow(title: "Publisher", value: publisher)
                }

                if let year = metadata.publishedYear {
                    metadataRow(title: "Published", value: String(year))
                }

                if let pageCount = metadata.pageCount {
                    metadataRow(title: "Pages", value: String(pageCount))
                }

                if !metadata.categories.isEmpty {
                    metadataRow(
                        title: "Categories",
                        value: metadata.categories.prefix(3).joined(separator: ", ")
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        sectionCard(title: "Reading Status") {
            Picker("Status", selection: $status) {
                ForEach(ReadingStatus.allCases) { readingStatus in
                    Label(readingStatus.displayName, systemImage: readingStatus.systemImage)
                        .tag(readingStatus)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .fieldChrome()
    }

    // MARK: - Actions

    private func confirmAndSave() {
        // Create book from edited metadata
        let book = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle.isEmpty ? nil : subtitle.trimmingCharacters(in: .whitespaces),
            publisher: publisher.isEmpty ? nil : publisher.trimmingCharacters(in: .whitespaces),
            isbn: metadata.bestISBN
        )

        // Set additional properties
        book.status = status
        book.pageCount = Int(pageCount)
        book.publishYear = metadata.publishedYear

        // Set cover image if loaded
        if let coverData = coverImageData {
            book.coverThumbnailData = coverData
            book.coverFullData = coverData
        }

        // Insert into context
        modelContext.insert(book)

        // Call completion handler
        onConfirm(book)
        dismiss()
    }

    private func loadCoverImage() async {
        guard let urlString = metadata.coverURL ?? metadata.thumbnailURL else {
            return
        }

        isLoadingCover = true
        coverLoadError = nil

        do {
            let service = ISBNLookupService()
            let data = try await service.fetchCoverImage(from: urlString)
            coverImageData = data
        } catch {
            coverLoadError = "Unable to load cover"
        }

        isLoadingCover = false
    }
}

// MARK: - Preview

#Preview {
    BookISBNConfirmationSheet(
        metadata: BookMetadata(
            title: "The Pragmatic Programmer",
            subtitle: "Your Journey to Mastery",
            authors: ["David Thomas", "Andrew Hunt"],
            publisher: "Addison-Wesley Professional",
            publishedYear: 2019,
            isbn13: "9780135957059",
            pageCount: 352,
            categories: ["Programming", "Software Engineering"],
            source: .googleBooks
        ),
        onConfirm: { book in
            print("Created book: \(book.title)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}

// MARK: - Convenience Extension for Displaying from Scanner

extension BookISBNConfirmationSheet {
    /// Create a confirmation sheet directly from an ISBN scan result.
    /// Performs the lookup automatically and shows loading state.
    struct FromScanResult: View {
        let isbn: String
        let onConfirm: (Book) -> Void
        let onCancel: () -> Void

        @State private var metadata: BookMetadata?
        @State private var isLoading = true
        @State private var error: Error?

        var body: some View {
            Group {
                if isLoading {
                    loadingView
                } else if let metadata = metadata {
                    BookISBNConfirmationSheet(
                        metadata: metadata,
                        onConfirm: onConfirm,
                        onCancel: onCancel
                    )
                } else {
                    errorView
                }
            }
            .task {
                await lookupISBN()
            }
        }

        private var loadingView: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Looking up book...")
                    .font(.headline)
                Text(ISBNValidator.format(isbn))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var errorView: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Book Not Found")
                    .font(.headline)

                Text(error?.localizedDescription ?? "Unable to find book information for this ISBN.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)

                    Button("Try Again") {
                        Task {
                            await lookupISBN()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private func lookupISBN() async {
            isLoading = true
            error = nil

            do {
                let service = ISBNLookupService()
                metadata = try await service.lookup(isbn: isbn)
            } catch {
                self.error = error
            }

            isLoading = false
        }
    }
}
