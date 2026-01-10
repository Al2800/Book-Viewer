import SwiftUI
import SwiftData
import PhotosUI

// MARK: - BookEditView

/// Form for creating or editing a book with all metadata fields.
/// Supports manual entry, editing existing books, and reviewing extracted metadata.
struct BookEditView: View {

    // MARK: - Mode

    enum Mode {
        case create
        case edit(Book)
        case createFromMetadata(BookMetadata)
    }

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let mode: Mode
    var onSave: ((Book) -> Void)?

    // MARK: - Editable State

    @State private var title = ""
    @State private var author = ""
    @State private var subtitle = ""
    @State private var isbn = ""
    @State private var publisher = ""
    @State private var publishYear = ""
    @State private var genre = ""
    @State private var pageCount = ""
    @State private var notes = ""
    @State private var status: ReadingStatus = .wantToRead

    // MARK: - Cover Image State

    @State private var coverImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCoverOptions = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                coverSection
                detailsSection
                metadataSection
                readingStatusSection
                notesSection
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { loadInitialValues() }
            .onChange(of: selectedPhotoItem) { _, newValue in
                loadSelectedPhoto(newValue)
            }
            .confirmationDialog("Cover Image", isPresented: $showCoverOptions) {
                coverOptionsDialog
            }
        }
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "Add Book"
        case .edit:
            return "Edit Book"
        case .createFromMetadata:
            return "Confirm Book"
        }
    }

    // MARK: - Cover Section

    private var coverSection: some View {
        Section {
            HStack {
                Spacer()

                Button {
                    showCoverOptions = true
                } label: {
                    coverImageView
                }
                .buttonStyle(.plain)

                Spacer()
            }
        } header: {
            Text("Cover")
        } footer: {
            Text("Tap to change cover image")
                .font(.caption)
        }
    }

    private var coverImageView: some View {
        Group {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.backgroundSecondary)
                    .overlay {
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Add Cover")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        .frame(width: 120, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    @ViewBuilder
    private var coverOptionsDialog: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            Text("Choose from Library")
        }

        if coverImage != nil {
            Button("Remove Cover", role: .destructive) {
                coverImage = nil
            }
        }

        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        Section("Book Details") {
            TextField("Title", text: $title)
                .textContentType(.none)

            TextField("Author", text: $author)
                .textContentType(.name)

            TextField("Subtitle", text: $subtitle)
                .textContentType(.none)
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        Section("Additional Info") {
            TextField("ISBN", text: $isbn)
                .keyboardType(.numberPad)

            TextField("Publisher", text: $publisher)

            TextField("Year Published", text: $publishYear)
                .keyboardType(.numberPad)

            TextField("Page Count", text: $pageCount)
                .keyboardType(.numberPad)

            Picker("Genre", selection: $genre) {
                Text("None").tag("")
                ForEach(BookGenre.allCases, id: \.rawValue) { genre in
                    Text(genre.displayName).tag(genre.rawValue)
                }
            }
        }
    }

    // MARK: - Reading Status Section

    private var readingStatusSection: some View {
        Section("Reading Status") {
            Picker("Status", selection: $status) {
                ForEach(ReadingStatus.allCases) { status in
                    Label(status.displayName, systemImage: status.systemImage)
                        .tag(status)
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes") {
            TextField("Add notes about this book...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(saveButtonTitle) {
                save()
            }
            .fontWeight(.semibold)
            .disabled(!isValidForSave)
        }
    }

    private var saveButtonTitle: String {
        switch mode {
        case .create, .createFromMetadata:
            return "Add Book"
        case .edit:
            return "Save"
        }
    }

    // MARK: - Validation

    private var isValidForSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !author.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Initial Values

    private func loadInitialValues() {
        switch mode {
        case .create:
            // Start with empty fields
            break

        case .edit(let book):
            title = book.title
            author = book.author
            subtitle = book.subtitle ?? ""
            isbn = book.isbn ?? ""
            publisher = book.publisher ?? ""
            publishYear = book.publishYear.map { String($0) } ?? ""
            genre = book.genre ?? ""
            pageCount = book.pageCount.map { String($0) } ?? ""
            notes = book.notes ?? ""
            status = book.status

            if let imageData = book.coverFullData ?? book.coverThumbnailData {
                coverImage = UIImage(data: imageData)
            }

        case .createFromMetadata(let metadata):
            title = metadata.title
            author = metadata.authorsFormatted
            subtitle = metadata.subtitle ?? ""
            isbn = metadata.isbn ?? ""
            publisher = metadata.publisher ?? ""
            publishYear = metadata.publishYear.map { String($0) } ?? ""
            genre = metadata.genre ?? ""
            pageCount = metadata.pageCount.map { String($0) } ?? ""

            if let imageData = metadata.coverImageData {
                coverImage = UIImage(data: imageData)
            }
        }
    }

    // MARK: - Photo Loading

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    coverImage = image
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        switch mode {
        case .create, .createFromMetadata:
            createBook()
        case .edit(let book):
            updateBook(book)
        }
    }

    private func createBook() {
        let book = Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle.isEmpty ? nil : subtitle,
            publisher: publisher.isEmpty ? nil : publisher,
            isbn: isbn.isEmpty ? nil : isbn
        )

        book.publishYear = Int(publishYear)
        book.genre = genre.isEmpty ? nil : genre
        book.pageCount = Int(pageCount)
        book.notes = notes.isEmpty ? nil : notes
        book.status = status

        if let image = coverImage {
            book.coverThumbnailData = image.jpegData(compressionQuality: 0.5)
            book.coverFullData = image.jpegData(compressionQuality: 0.8)
        }

        modelContext.insert(book)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
            onSave?(book)
            dismiss()
        } catch {
            HapticManager.error()
        }
    }

    private func updateBook(_ book: Book) {
        book.title = title.trimmingCharacters(in: .whitespaces)
        book.author = author.trimmingCharacters(in: .whitespaces)
        book.subtitle = subtitle.isEmpty ? nil : subtitle
        book.publisher = publisher.isEmpty ? nil : publisher
        book.isbn = isbn.isEmpty ? nil : isbn
        book.publishYear = Int(publishYear)
        book.genre = genre.isEmpty ? nil : genre
        book.pageCount = Int(pageCount)
        book.notes = notes.isEmpty ? nil : notes
        book.status = status
        book.dateModified = Date()

        if let image = coverImage {
            book.coverThumbnailData = image.jpegData(compressionQuality: 0.5)
            book.coverFullData = image.jpegData(compressionQuality: 0.8)
        } else {
            book.coverThumbnailData = nil
            book.coverFullData = nil
        }

        do {
            try modelContext.save()
            HapticManager.notification(.success)
            onSave?(book)
            dismiss()
        } catch {
            HapticManager.error()
        }
    }
}

// MARK: - BookMetadata

/// Extracted or looked-up book metadata before creating a Book model.
struct BookMetadata: Identifiable, Sendable {
    let id = UUID()

    var title: String
    var authors: [String]
    var subtitle: String?
    var isbn: String?
    var publisher: String?
    var publishYear: Int?
    var genre: String?
    var pageCount: Int?
    var coverImageURL: URL?
    var coverImageData: Data?

    /// Authors formatted as a single string.
    var authorsFormatted: String {
        authors.joined(separator: ", ")
    }

    init(
        title: String,
        authors: [String] = [],
        subtitle: String? = nil,
        isbn: String? = nil,
        publisher: String? = nil,
        publishYear: Int? = nil,
        genre: String? = nil,
        pageCount: Int? = nil,
        coverImageURL: URL? = nil,
        coverImageData: Data? = nil
    ) {
        self.title = title
        self.authors = authors
        self.subtitle = subtitle
        self.isbn = isbn
        self.publisher = publisher
        self.publishYear = publishYear
        self.genre = genre
        self.pageCount = pageCount
        self.coverImageURL = coverImageURL
        self.coverImageData = coverImageData
    }
}

// MARK: - BookGenre

/// Common book genres for categorization.
enum BookGenre: String, CaseIterable {
    case fiction
    case nonFiction = "non-fiction"
    case sciFi = "science-fiction"
    case fantasy
    case mystery
    case thriller
    case romance
    case biography
    case selfHelp = "self-help"
    case business
    case history
    case science
    case philosophy
    case psychology
    case poetry
    case other

    var displayName: String {
        switch self {
        case .fiction: return "Fiction"
        case .nonFiction: return "Non-Fiction"
        case .sciFi: return "Science Fiction"
        case .fantasy: return "Fantasy"
        case .mystery: return "Mystery"
        case .thriller: return "Thriller"
        case .romance: return "Romance"
        case .biography: return "Biography"
        case .selfHelp: return "Self-Help"
        case .business: return "Business"
        case .history: return "History"
        case .science: return "Science"
        case .philosophy: return "Philosophy"
        case .psychology: return "Psychology"
        case .poetry: return "Poetry"
        case .other: return "Other"
        }
    }
}

// MARK: - Preview

#Preview("Create Book") {
    BookEditView(mode: .create)
        .modelContainer(for: Book.self, inMemory: true)
}

#Preview("Edit Book") {
    let book = Book(title: "Atomic Habits", author: "James Clear")
    book.publisher = "Avery"
    book.publishYear = 2018
    book.genre = "self-help"

    return BookEditView(mode: .edit(book))
        .modelContainer(for: Book.self, inMemory: true)
}

#Preview("From Metadata") {
    let metadata = BookMetadata(
        title: "The Psychology of Money",
        authors: ["Morgan Housel"],
        publisher: "Harriman House",
        publishYear: 2020,
        genre: "business"
    )

    return BookEditView(mode: .createFromMetadata(metadata))
        .modelContainer(for: Book.self, inMemory: true)
}
