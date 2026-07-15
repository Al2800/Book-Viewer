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

    /// Guards against double-saving: the first-book milestone delays
    /// dismissal by ~2 seconds, during which another Save tap would
    /// otherwise insert a duplicate book.
    @State private var isSaving = false

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
                    primarySections
                    BookEditMetadataSection(
                        isbn: $isbn,
                        publisher: $publisher,
                        publishYear: $publishYear,
                        pageCount: $pageCount,
                        genre: $genre,
                        focusedField: $focusedField
                    )
                    BookEditReadingStatusSection(status: $status)
                    BookEditNotesSection(
                        notes: $notes,
                        focusedField: $focusedField
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.formScrollView)
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
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.keyboardDoneButton)
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

    @ViewBuilder
    private var primarySections: some View {
        if prioritizesRequiredDetails {
            detailsSection
            coverSection
        } else {
            coverSection
            detailsSection
        }
    }

    private var coverSection: some View {
        BookEditCoverSection(
            coverImage: $coverImage,
            selectedPhotoItem: $selectedPhotoItem,
            showCameraPicker: $showCameraPicker
        )
    }

    private var detailsSection: some View {
        BookEditDetailsSection(
            title: $title,
            author: $author,
            subtitle: $subtitle,
            focusedField: $focusedField,
            titleShakeTrigger: titleShakeTrigger,
            authorShakeTrigger: authorShakeTrigger
        )
    }

    /// Manual entry should start with the required book details rather than an optional cover.
    private var prioritizesRequiredDetails: Bool {
        switch mode {
        case .create:
            return true
        case .createFromMetadata(let metadata):
            return metadata.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                metadata.authors.isEmpty &&
                metadata.coverImageData == nil &&
                metadata.coverImageURL == nil
        case .edit:
            return false
        }
    }

    private var isTitleValid: Bool {
        makeSaveDraft(includeCoverData: false).isValidForSave
    }

    private var isAuthorBlank: Bool {
        makeSaveDraft(includeCoverData: false).isAuthorBlank
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.cancelButton)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(saveButtonTitle) {
                validateAndSave()
            }
            .fontWeight(.semibold)
            .disabled(!isValidForSave || isSaving)
            .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.saveButton)
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
        isTitleValid
    }

    /// Validate fields and either save or shake invalid fields
    private func validateAndSave() {
        guard !isSaving else { return }

        var hasError = false

        if !isTitleValid {
            titleShakeTrigger += 1
            hasError = true
        }

        // Author is optional; nudge if missing but do not block save.
        if isAuthorBlank {
            authorShakeTrigger += 1
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

        applyDraft(BookEditDraft(source: editSource))
    }

    private var editSource: BookEditSource {
        switch mode {
        case .create: return .create
        case .edit(let book): return .edit(book)
        case .createFromMetadata(let metadata): return .metadata(metadata)
        }
    }

    private func applyDraft(_ draft: BookEditDraft) {
        title = draft.title
        author = draft.author
        subtitle = draft.subtitle
        isbn = draft.isbn
        publisher = draft.publisher
        publishYear = draft.publishYear
        genre = draft.genre
        pageCount = draft.pageCount
        notes = draft.notes
        status = draft.status

        if let imageData = draft.coverImageData {
            coverImage = UIImage(data: imageData)
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
        let book = makeSaveDraft().makeBook()

        isSaving = true
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
            isSaving = false
            HapticManager.error()
        }
    }

    private func updateBook(_ book: Book) {
        makeSaveDraft().apply(to: book)

        do {
            try modelContext.save()
            HapticManager.notification(.success)
            onSave?(book)
            dismiss()
        } catch {
            HapticManager.error()
        }
    }

    private func makeSaveDraft(includeCoverData: Bool = true) -> BookEditSaveDraft {
        BookEditSaveDraft(
            title: title,
            author: author,
            subtitle: subtitle,
            isbn: isbn,
            publisher: publisher,
            publishYear: publishYear,
            genre: genre,
            pageCount: pageCount,
            notes: notes,
            status: status,
            coverImageData: includeCoverData ? coverImageData : nil
        )
    }

    private var coverImageData: BookEditCoverImageData? {
        guard let image = coverImage else { return nil }
        return BookEditCoverImageData(
            thumbnailData: image.jpegData(compressionQuality: 0.5),
            fullData: image.jpegData(compressionQuality: 0.8)
        )
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
