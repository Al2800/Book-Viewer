import SwiftUI
import SwiftData

// MARK: - QuoteDetailView

/// Detail view for viewing, editing, and managing individual quotes.
struct QuoteDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var quote: Quote
    private let deletionPrompt = QuoteDeletionPrompt()

    // MARK: - State

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var showSourceImage = false
    @State private var showMarkingPicker = false
    @State private var showShareSheet = false
    @State private var showStudioSheet = false
    @State private var shareItems: [Any] = []
    @State private var organizationSheet: OrganizationSheet?

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
                // Design Quote Card in Studio Action Card
                if !isEditing {
                    Button {
                        HapticManager.light()
                        showStudioSheet = true
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.title3)
                                .foregroundStyle(Color.gildedAccent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Design Quote Card")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)

                                Text("Style with v2 editorial themes & export to social, Obsidian or Notion")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .fill(Color.warmVellum)
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                                        .stroke(Color.gildedAccent.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)
                }

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

                // Metadata section
                metadataSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)

                // Collections and tags
                QuoteDetailOrganizeSection(
                    quote: quote,
                    onCollections: {
                        HapticManager.light()
                        organizationSheet = .collections
                    },
                    onTags: {
                        HapticManager.light()
                        organizationSheet = .tags
                    }
                )
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)

                // Source image button
                if quote.sourceImageData != nil {
                    QuoteDetailSourceImageButton {
                        showSourceImage = true
                    }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)
                }

                // Book info
                if let book = quote.book {
                    QuoteDetailBookSection(book: book)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)
                }
            }
            .padding()
            .animation(reduceMotion ? .none : .smoothSpring.delay(0.1), value: hasAppeared)
        }
        .background(Color.backgroundPrimary)
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
                            showStudioSheet = true
                        } label: {
                            Label("Design Quote Card", systemImage: "sparkles.rectangle.stack")
                        }

                        Button {
                            shareQuote()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button {
                            organizationSheet = .collections
                        } label: {
                            Label("Add to Collection", systemImage: "folder.badge.plus")
                        }

                        Button {
                            organizationSheet = .tags
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
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
            deletionPrompt.title,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(deletionPrompt.destructiveActionTitle, role: .destructive) {
                deleteQuote()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deletionPrompt.message)
        }
        .sheet(isPresented: $showSourceImage) {
            QuoteSourceImageSheet(
                imageData: quote.sourceImageData,
                onDone: {
                    showSourceImage = false
                }
            )
        }
        .sheet(isPresented: $showMarkingPicker) {
            QuoteMarkingPickerSheet(
                markingType: $quote.markingType,
                onCancel: {
                    showMarkingPicker = false
                },
                onSelect: {
                    showMarkingPicker = false
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            QuoteShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showStudioSheet) {
            QuoteCardStudioView(quote: quote)
        }
        .sheet(item: $organizationSheet) { destination in
            switch destination {
            case .collections:
                AddToCollectionSheet(quote: quote) {
                    organizationSheet = nil
                }
            case .tags:
                AddTagToQuoteSheet(quote: quote) {
                    organizationSheet = nil
                }
            }
        }
    }

    private enum OrganizationSheet: String, Identifiable {
        case collections
        case tags

        var id: Self { self }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isEditing {
                TextEditor(text: $editedText)
                    .font(.quoteBody)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .fieldChrome(minHeight: 150)
                    .accessibilityIdentifier(AccessibilityIdentifiers.QuoteDetail.textEditor)
            } else {
                Text("“\(quote.text)”")
                    .font(.quoteDisplay)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                // Favorite indicator
                if quote.isFavorite {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.gildedAccent)
                        Text("Favorite")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.gildedAccent)
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.warmVellum)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Margin Note Section

    private var marginNoteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "pencil.line")
                    .font(.caption)
                    .foregroundStyle(Color.goldFoil)
                Text("Margin Note")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }

            if isEditing {
                TextField("Add a margin note...", text: $editedMarginNote)
                    .font(.marginScript)
                    .textFieldStyle(.plain)
                    .fieldChrome(minHeight: 56)
            } else if let note = quote.marginNote {
                Text(note)
                    .font(.marginScript)
                    .foregroundStyle(Color.textPrimary)
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.warmVellum.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.quoteBorder.opacity(0.5), lineWidth: Stroke.hairline.width)
                )
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Details")
                .sectionHeaderStyle()

            // Page number
            HStack {
                Label("Page", systemImage: "doc")
                Spacer()
                if isEditing {
                    TextField("Page", text: $editedPageNumber)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .fieldChrome()
                        .frame(width: 96)
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
        .padding(Spacing.lg)
        .paperCard()
    }

    // MARK: - Actions

    private func startEditing() {
        HapticManager.light()
        let editFields = QuoteDetailEditFields(quote: quote)
        editedText = editFields.text
        editedMarginNote = editFields.marginNote
        editedPageNumber = editFields.pageNumberText
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
        QuoteDetailEditDraft(
            text: editedText,
            marginNote: editedMarginNote,
            pageNumberText: editedPageNumber
        )
        .apply(to: quote, in: modelContext)

        try? modelContext.save()
        HapticManager.success()
        withAnimation(reduceMotion ? .none : .smoothSpring) {
            isEditing = false
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = QuoteDetailTextFormatter.shareText(for: quote)
        HapticManager.success()
    }

    /// Render the typographic share card once, then present the sheet
    /// with the image alongside the plain text.
    private func shareQuote() {
        HapticManager.light()

        var items: [Any] = []
        if let image = QuoteShareImageRenderer.render(quote: quote) {
            items.append(image)
        }
        items.append(shareableQuoteText)
        shareItems = items

        showShareSheet = true
    }

    /// Formatted quote text for sharing
    private var shareableQuoteText: String {
        QuoteDetailTextFormatter.shareText(for: quote)
    }

    private func deleteQuote() {
        HapticManager.warning()
        modelContext.delete(quote)
        try? modelContext.save()
        dismiss()
    }
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
