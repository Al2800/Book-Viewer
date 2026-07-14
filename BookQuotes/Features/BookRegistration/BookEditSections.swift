import SwiftUI
import PhotosUI

struct BookEditCoverSection: View {
    @Binding var coverImage: UIImage?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var showCameraPicker: Bool

    var body: some View {
        SectionCard(title: "Cover", subtitle: "Optional") {
            VStack(spacing: Spacing.md) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
                        .buttonStyle(.secondaryCompact)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity)
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Library", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.secondaryCompact)
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
                        .buttonStyle(.secondaryCompact)
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
}

struct BookEditDetailsSection: View {
    @Binding var title: String
    @Binding var author: String
    @Binding var subtitle: String
    @FocusState.Binding var focusedField: BookEditView.Field?
    let titleShakeTrigger: Int
    let authorShakeTrigger: Int

    var body: some View {
        SectionCard(title: "Book Details") {
            VStack(spacing: Spacing.md) {
                TextField("Title", text: $title)
                    .textContentType(.none)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .title)
                    .onSubmit { focusedField = .author }
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .shake(trigger: titleShakeTrigger)
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.titleField)

                TextField("Author", text: $author)
                    .textContentType(.name)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .author)
                    .onSubmit { focusedField = .subtitle }
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .shake(trigger: authorShakeTrigger)
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.authorField)

                TextField("Subtitle", text: $subtitle)
                    .textContentType(.none)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .subtitle)
                    .onSubmit { focusedField = nil }
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.subtitleField)
            }
        }
    }
}

struct BookEditMetadataSection: View {
    @Binding var isbn: String
    @Binding var publisher: String
    @Binding var publishYear: String
    @Binding var pageCount: String
    @Binding var genre: String
    @FocusState.Binding var focusedField: BookEditView.Field?

    var body: some View {
        SectionCard(title: "Additional Info", subtitle: "Optional") {
            VStack(spacing: Spacing.md) {
                TextField("ISBN", text: $isbn)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .isbn)
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.isbnField)

                TextField("Publisher", text: $publisher)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .publisher)
                    .onSubmit { focusedField = .publishYear }
                    .textFieldStyle(.plain)
                    .fieldChrome()
                    .accessibilityIdentifier(AccessibilityIdentifiers.BookEdit.publisherField)

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
                    ForEach(BookEditOptions.genreOptions, id: \.rawValue) { genre in
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
}

struct BookEditReadingStatusSection: View {
    @Binding var status: ReadingStatus

    var body: some View {
        SectionCard(title: "Reading Status") {
            Picker("Status", selection: $status) {
                ForEach(ReadingStatus.allCases) { status in
                    Label(status.displayName, systemImage: status.systemImage)
                        .tag(status)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AccessibilityIdentifiers.BookDetail.statusPicker)
        }
    }
}

struct BookEditNotesSection: View {
    @Binding var notes: String
    @FocusState.Binding var focusedField: BookEditView.Field?

    var body: some View {
        SectionCard(title: "Notes", subtitle: "Optional") {
            TextField("Add notes about this book...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .submitLabel(.done)
                .focused($focusedField, equals: .notes)
                .onSubmit { focusedField = nil }
                .textFieldStyle(.plain)
                .fieldChrome(minHeight: 88)
        }
    }
}
