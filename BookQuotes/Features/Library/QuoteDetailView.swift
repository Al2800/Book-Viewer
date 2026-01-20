import SwiftUI
import SwiftData
import UIKit

// MARK: - QuoteDetailView

/// Detail view for viewing, editing, and managing individual quotes.
struct QuoteDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var quote: Quote

    // MARK: - State

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var showSourceImage = false
    @State private var showMarkingPicker = false
    @State private var showShareSheet = false

    // MARK: - Editing State

    @State private var editedText: String = ""
    @State private var editedMarginNote: String = ""
    @State private var editedPageNumber: String = ""

    // MARK: - Animation State

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Focus State

    @FocusState private var isPageNumberFocused: Bool

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Quote text
                quoteSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)

                // Margin note if present
                if quote.marginNote != nil || isEditing {
                    marginNoteSection
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)
                }

                Divider()
                    .opacity(hasAppeared ? 1 : 0)

                // Metadata section
                metadataSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)

                // Source image button
                if quote.sourceImageData != nil {
                    sourceImageButton
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)
                }

                // Book info
                if let book = quote.book {
                    bookSection(book)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)
                }
            }
            .padding()
            .animation(reduceMotion ? .none : .smoothSpring.delay(0.1), value: hasAppeared)
        }
        // Edit mode transition animation
        .animation(reduceMotion ? .none : .smoothSpring, value: isEditing)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.15)) {
                hasAppeared = true
            }
        }
        .navigationTitle("Quote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Favorite button (only when not editing)
            if !isEditing {
                ToolbarItem(placement: .primaryAction) {
                    HeartBurstButton(isFavorite: $quote.isFavorite) {
                        try? modelContext.save()
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.favoriteButton)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Done") {
                        saveEdits()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.doneButton)
                } else {
                    Menu {
                        Button {
                            startEditing()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button {
                            copyToClipboard()
                        } label: {
                            Label("Copy Quote", systemImage: "doc.on.doc")
                        }

                        Button {
                            shareQuote()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Quote", systemImage: "trash")
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.deleteButton)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.Common.moreMenuButton)
                }
            }

            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.cancelButton)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        HapticManager.light()
                        isPageNumberFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .confirmationDialog(
            "Delete Quote?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteQuote()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showSourceImage) {
            sourceImageSheet
        }
        .sheet(isPresented: $showMarkingPicker) {
            markingPickerSheet
        }
        .sheet(isPresented: $showShareSheet) {
            QuoteShareSheet(text: shareableQuoteText)
        }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isEditing {
                TextEditor(text: $editedText)
                    .font(.quoteBody)
                    .frame(minHeight: 150)
                    .padding(Spacing.sm)
                    .background(Color.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                    .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.textEditor)
            } else {
                Text(quote.text)
                    .quoteTextStyle()

                // Favorite indicator
                if quote.isFavorite {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("Favorite")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
    }

    // MARK: - Margin Note Section

    private var marginNoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Margin Note", systemImage: "note.text")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isEditing {
                TextField("Add a margin note...", text: $editedMarginNote)
                    .font(.body)
                    .padding(Spacing.sm)
                    .background(Color.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            } else if let note = quote.marginNote {
                Text(note)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Details")
                .font(.sectionHeader)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Page number
            HStack {
                Label("Page", systemImage: "doc")
                Spacer()
                if isEditing {
                    TextField("Page", text: $editedPageNumber)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($isPageNumberFocused)
                } else {
                    Text(quote.pageNumber.map { "\($0)" } ?? "Unknown")
                        .foregroundStyle(.secondary)
                }
            }

            // Marking type
            HStack {
                Label("Marking", systemImage: "highlighter")
                Spacer()
                Button {
                    showMarkingPicker = true
                } label: {
                    MarkingTypeBadge(
                        markingType: quote.markingType,
                        customMarking: quote.customMarkingDefinition
                    )
                }
                .disabled(!isEditing)
            }

            // Capture date
            HStack {
                Label("Captured", systemImage: "calendar")
                Spacer()
                Text(quote.captureDate.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }

            // Confidence
            if let confidence = quote.confidence {
                HStack {
                    Label("AI Confidence", systemImage: "brain")
                    Spacer()
                    ConfidenceIndicator(confidence: confidence, style: .label)
                }
            }
        }
        .font(.subheadline)
    }

    // MARK: - Source Image Button

    private var sourceImageButton: some View {
        Button {
            showSourceImage = true
        } label: {
            HStack {
                Label("View Source Image", systemImage: "photo")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.sourceImageButton)
    }

    // MARK: - Book Section

    private func bookSection(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("From")
                .font(.sectionHeader)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            NavigationLink(value: book) {
                BookHeaderView(book: book, style: .compact)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Source Image Sheet

    @ViewBuilder
    private var sourceImageSheet: some View {
        NavigationStack {
            if let imageData = quote.sourceImageData,
               let uiImage = UIImage(data: imageData) {
                ScrollView {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                .navigationTitle("Source Image")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showSourceImage = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Marking Picker Sheet

    private var markingPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(MarkingType.allCases, id: \.self) { type in
                    Button {
                        quote.markingType = type
                        showMarkingPicker = false
                    } label: {
                        HStack {
                            MarkingTypeBadge(markingType: type)
                            Spacer()
                            if quote.markingType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Marking Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showMarkingPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func startEditing() {
        HapticManager.light()
        editedText = quote.text
        editedMarginNote = quote.marginNote ?? ""
        editedPageNumber = quote.pageNumber.map { "\($0)" } ?? ""
        withAnimation(reduceMotion ? .none : .smoothSpring) {
            isEditing = true
        }
    }

    private func cancelEditing() {
        HapticManager.light()
        withAnimation(reduceMotion ? .none : .smoothSpring) {
            isEditing = false
        }
    }

    private func saveEdits() {
        quote.text = editedText
        quote.marginNote = editedMarginNote.isEmpty ? nil : editedMarginNote
        quote.pageNumber = Int(editedPageNumber)
        quote.dateModified = Date()

        try? modelContext.save()
        HapticManager.success()
        withAnimation(reduceMotion ? .none : .smoothSpring) {
            isEditing = false
        }
    }

    private func copyToClipboard() {
        var text = "\"\(quote.text)\""
        if let book = quote.book {
            text += "\n\n— \(book.title) by \(book.author)"
            if let page = quote.pageNumber {
                text += ", p. \(page)"
            }
        }
        UIPasteboard.general.string = text
        HapticManager.success()
    }

    private func shareQuote() {
        HapticManager.light()
        showShareSheet = true
    }

    /// Formatted quote text for sharing
    private var shareableQuoteText: String {
        var text = "\"\(quote.text)\""
        if let book = quote.book {
            text += "\n\n— \(book.title) by \(book.author)"
            if let page = quote.pageNumber {
                text += ", p. \(page)"
            }
        }
        return text
    }

    private func deleteQuote() {
        HapticManager.warning()
        modelContext.delete(quote)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - QuoteShareSheet

/// Simple share sheet for quotes using UIActivityViewController.
struct QuoteShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return activityVC
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuoteDetailView(
            quote: {
                let book = Book(title: "Atomic Habits", author: "James Clear")
                let quote = Quote(
                    text: "Every action you take is a vote for the type of person you wish to become. No single instance will transform your beliefs, but as the votes build up, so does the evidence of your new identity.",
                    book: book
                )
                quote.pageNumber = 38
                quote.marginNote = "This is the key insight of the whole book!"
                quote.confidence = 0.92
                quote.isFavorite = true
                return quote
            }()
        )
    }
}
