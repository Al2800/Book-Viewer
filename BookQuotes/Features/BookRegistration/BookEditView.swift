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
    @State private var showCameraPicker = false
    @State private var hasLoadedInitialValues = false

    // MARK: - Milestone State

    @StateObject private var milestoneManager = MilestoneManager()

    // MARK: - Validation State

    @State private var titleShakeTrigger = 0
    @State private var authorShakeTrigger = 0

    // MARK: - Focus State

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, author, subtitle
        case isbn, publishYear, pageCount
        case publisher, genre, notes
    }

    // MARK: - Query for book count

    @Query private var existingBooks: [Book]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    coverSection
                    detailsSection
                    metadataSection
                    readingStatusSection
                    notesSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.backgroundPrimary)
            .scrollDismissesKeyboard(.interactively)
            .tint(.brand)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { loadInitialValues() }
            .onChange(of: selectedPhotoItem) { _, newValue in
                loadSelectedPhoto(newValue)
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraImagePicker(sourceType: .camera) { image in
                    coverImage = image
                }
            }
            .milestoneCelebration(manager: milestoneManager)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        HapticManager.light()
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
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

    // MARK: - Cover Section

    private var coverSection: some View {
        sectionCard(title: "Cover", subtitle: "Optional") {
            VStack(spacing: Spacing.md) {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    coverImageView
                }
                .buttonStyle(.plain)

                Text("Tap the cover to choose a photo, or use the buttons below.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: Spacing.sm) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCameraPicker = true
                        } label: {
                            Label("Camera", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        .tint(.brand)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity)
                    }

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        Label("Library", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity)

                    if coverImage != nil {
                        Button(role: .destructive) {
                            coverImage = nil
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity)
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
        .frame(width: 140, height: 210)
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

    // MARK: - Details Section

    private var detailsSection: some View {
        sectionCard(title: "Book Details") {
            VStack(spacing: Spacing.md) {
                TextField("Title", text: $title)
                    .textContentType(.none)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .title)
                    .onSubmit { focusedField = .author }
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .shake(trigger: titleShakeTrigger)

                TextField("Author", text: $author)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .author)
                    .onSubmit { focusedField = .subtitle }
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .shake(trigger: authorShakeTrigger)

                TextField("Subtitle", text: $subtitle)
                    .textContentType(.none)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .subtitle)
                    .onSubmit { focusedField = nil }
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

    // MARK: - Metadata Section

    private var metadataSection: some View {
        sectionCard(title: "Additional Info", subtitle: "Optional") {
            VStack(spacing: Spacing.md) {
                TextField("ISBN", text: $isbn)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .isbn)
                    .textFieldStyle(.plain)
                    .fieldChrome()

                TextField("Publisher", text: $publisher)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .publisher)
                    .onSubmit { focusedField = .publishYear }
                    .textFieldStyle(.plain)
                    .fieldChrome()

                HStack(spacing: Spacing.md) {
                    TextField("Year", text: $publishYear)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .publishYear)
                        .textFieldStyle(.plain)
                        .fieldChrome()
                        .frame(maxWidth: .infinity)

                    TextField("Pages", text: $pageCount)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .pageCount)
                        .textFieldStyle(.plain)
                        .fieldChrome()
                        .frame(maxWidth: .infinity)
                }

                Picker("Genre", selection: $genre) {
                    Text("None").tag("")
                    ForEach(BookGenre.allCases, id: \.rawValue) { genre in
                        Text(genre.displayName).tag(genre.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .focused($focusedField, equals: .genre)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fieldChrome()
            }
        }
    }

    // MARK: - Reading Status Section

    private var readingStatusSection: some View {
        sectionCard(title: "Reading Status") {
            Picker("Status", selection: $status) {
                ForEach(ReadingStatus.allCases) { status in
                    Label(status.displayName, systemImage: status.systemImage)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        sectionCard(title: "Notes", subtitle: "Optional") {
            TextField("Add notes about this book...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .submitLabel(.done)
                .focused($focusedField, equals: .notes)
                .onSubmit { focusedField = nil }
                .textFieldStyle(.plain)
                .fieldChrome(minHeight: 88)
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
                validateAndSave()
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
        isTitleValid && isAuthorValid
    }

    /// Validate fields and either save or shake invalid fields
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

        save()
    }

    // MARK: - Initial Values

    private func loadInitialValues() {
        guard !hasLoadedInitialValues else { return }
        hasLoadedInitialValues = true

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
        // Check if this is the first book before adding
        let isFirstBook = existingBooks.isEmpty

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

            // Show first book milestone celebration
            if isFirstBook {
                milestoneManager.triggerFirstBook()
                // Delay dismiss to show celebration
                Task {
                    try? await Task.sleep(for: .seconds(2.2))
                    await MainActor.run {
                        onSave?(book)
                        dismiss()
                    }
                }
            } else {
                HapticManager.notification(.success)
                onSave?(book)
                dismiss()
            }
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

// MARK: - Camera Image Picker

private struct CameraImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let image {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
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
    let book: Book = {
        let book = Book(title: "Atomic Habits", author: "James Clear")
        book.publisher = "Avery"
        book.publishYear = 2018
        book.genre = "self-help"
        return book
    }()

    BookEditView(mode: .edit(book))
        .modelContainer(for: Book.self, inMemory: true)
}

#Preview("From Metadata") {
    let metadata = BookMetadata(
        title: "The Psychology of Money",
        authors: ["Morgan Housel"],
        publisher: "Harriman House",
        publishedYear: 2020,
        categories: ["business"]
    )

    BookEditView(mode: .createFromMetadata(metadata))
        .modelContainer(for: Book.self, inMemory: true)
}
