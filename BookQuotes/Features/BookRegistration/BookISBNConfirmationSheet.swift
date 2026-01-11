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
            Form {
                coverSection
                detailsSection
                metadataSection
                statusSection
            }
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

    // MARK: - Sections

    @ViewBuilder
    private var coverSection: some View {
        Section {
            HStack {
                Spacer()
                coverImageView
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var coverImageView: some View {
        Group {
            if isLoadingCover {
                ProgressView()
                    .frame(width: 120, height: 180)
            } else if let data = coverImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120, maxHeight: 180)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            } else {
                // Placeholder when no cover available
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 120, height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            if let error = coverLoadError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                    }
            }
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        Section("Book Details") {
            TextField("Title", text: $title)
                .textContentType(.name)
                .shake(trigger: titleShakeTrigger)

            TextField("Author", text: $author)
                .textContentType(.name)
                .shake(trigger: authorShakeTrigger)

            TextField("Subtitle (optional)", text: $subtitle)
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
        Section("From Database") {
            if let isbn = metadata.bestISBN {
                LabeledContent("ISBN", value: ISBNValidator.format(isbn))
            }

            if !publisher.isEmpty {
                LabeledContent("Publisher", value: publisher)
            }

            if let year = metadata.publishedYear {
                LabeledContent("Published", value: String(year))
            }

            if let pageCount = metadata.pageCount {
                LabeledContent("Pages", value: String(pageCount))
            }

            if !metadata.categories.isEmpty {
                LabeledContent("Categories") {
                    Text(metadata.categories.prefix(3).joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section("Reading Status") {
            Picker("Status", selection: $status) {
                ForEach(ReadingStatus.allCases) { readingStatus in
                    Label(readingStatus.displayName, systemImage: readingStatus.systemImage)
                        .tag(readingStatus)
                }
            }
            .pickerStyle(.menu)
        }
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
