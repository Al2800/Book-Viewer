import SwiftUI
import SwiftData

// MARK: - Extraction Review View

/// Main view for reviewing, editing, and confirming extracted quotes before saving.
/// Shows a split view with page thumbnails on the left and quote editor on the right.
struct ExtractionReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: CaptureSession
    let book: Book

    @State private var editingQuotes: [EditableQuote] = []
    @State private var selectedPage: PageCapture?
    @State private var showingSaveConfirmation = false
    @State private var showingAddQuoteSheet = false
    @State private var showingDiscardAlert = false
    @State private var isSaving = false
    @State private var saveError: Error?
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Milestone State

    @StateObject private var milestoneManager = MilestoneManager()
    @Query private var existingQuotes: [Quote]

    /// Completion handler called after successful save
    var onComplete: (() -> Void)?

    // MARK: - Computed Properties

    private var quoteCounts: [UUID: Int] {
        Dictionary(grouping: editingQuotes, by: \.pageId)
            .mapValues { $0.count }
    }

    private var totalQuoteCount: Int {
        editingQuotes.count
    }

    private var hasChanges: Bool {
        !editingQuotes.isEmpty
    }

    private var quotesForSelectedPage: [EditableQuote] {
        guard let page = selectedPage else { return [] }
        return editingQuotes.filter { $0.pageId == page.id }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left: Page thumbnails
                PageListView(
                    session: session,
                    selection: $selectedPage,
                    quoteCounts: quoteCounts
                )

                Divider()

                // Right: Quote editor for selected page
                if let page = selectedPage {
                    PageQuoteEditor(
                        page: page,
                        quotes: bindingForPage(page),
                        onAddManualQuote: {
                            showingAddQuoteSheet = true
                        }
                    )
                } else {
                    noSelectionView
                }
            }
            .navigationTitle("Review Extractions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have \(totalQuoteCount) unsaved quotes. Are you sure you want to discard them?")
            }
            .alert("Save Error", isPresented: .init(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError?.localizedDescription ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingAddQuoteSheet) {
                if let page = selectedPage {
                    AddManualQuoteSheet(
                        pageId: page.id,
                        pageNumber: page.detectedPageNumber,
                        onAdd: { quote in
                            editingQuotes.append(quote)
                        }
                    )
                }
            }
            .confirmationDialog(
                "Save \(totalQuoteCount) Quotes",
                isPresented: $showingSaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save to \"\(book.title)\"") {
                    saveAllQuotes()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("These quotes will be added to your library.")
            }
        }
        .interactiveDismissDisabled(hasChanges)
        .onAppear {
            loadExtractedQuotes()
            selectFirstPage()
            // Trigger entrance animation
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring.delay(0.2)) {
                hasAppeared = true
            }
        }
        // Animate quote count changes
        .animation(reduceMotion ? .none : .snappy, value: totalQuoteCount)
        .milestoneCelebration(manager: milestoneManager)
    }

    // MARK: - Subviews

    private var noSelectionView: some View {
        ContentUnavailableView {
            Label("Select a Page", systemImage: "doc.text.viewfinder")
        } description: {
            Text("Choose a page from the left to review its extracted quotes")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                HapticManager.light()
                if hasChanges {
                    showingDiscardAlert = true
                } else {
                    dismiss()
                }
            }
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("\(totalQuoteCount) Quotes")
                    .font(.headline)
                    .contentTransition(.numericText())
                Text(book.title)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .opacity(hasAppeared ? 1 : 0)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                HapticManager.medium()
                showingSaveConfirmation = true
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Save All")
                        .fontWeight(.semibold)
                }
            }
            .disabled(editingQuotes.isEmpty || isSaving)
        }
    }

    // MARK: - Bindings

    private func bindingForPage(_ page: PageCapture) -> Binding<[EditableQuote]> {
        Binding(
            get: {
                editingQuotes.filter { $0.pageId == page.id }
            },
            set: { newQuotes in
                // Remove old quotes for this page
                editingQuotes.removeAll { $0.pageId == page.id }
                // Add new quotes
                editingQuotes.append(contentsOf: newQuotes)
            }
        )
    }

    // MARK: - Actions

    private func loadExtractedQuotes() {
        // In a real implementation, this would load quotes from the session's processing results
        // For now, we create placeholder quotes based on the session's captures
        // The actual quotes would come from BatchProcessingService results

        // This is where you'd integrate with the actual extraction results
        // For each capture that has been processed, load its extracted quotes
    }

    private func selectFirstPage() {
        if selectedPage == nil {
            selectedPage = session.captures
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .first
        }
    }

    private func saveAllQuotes() {
        guard !editingQuotes.isEmpty else { return }

        // Capture quote count before saving for milestone check
        let previousCount = existingQuotes.count
        let savedCount = editingQuotes.count

        isSaving = true

        Task {
            do {
                let saveService = QuoteSaveService(modelContext: modelContext)

                let extractedQuotes = editingQuotes.map { $0.toExtractedQuote() }
                let result = saveService.saveMultiple(extractedQuotes, to: book)

                await MainActor.run {
                    isSaving = false

                    if result.isFullSuccess {
                        // Check if we crossed any milestone
                        let newTotal = previousCount + savedCount
                        let crossedMilestone = MilestoneManager.quoteMilestones.first { milestone in
                            previousCount < milestone && newTotal >= milestone
                        }

                        if let milestone = crossedMilestone {
                            milestoneManager.checkQuoteMilestone(totalQuotes: milestone)
                            // Delay dismiss to show celebration
                            Task {
                                try? await Task.sleep(for: .seconds(2.2))
                                await MainActor.run {
                                    onComplete?()
                                    dismiss()
                                }
                            }
                        } else {
                            HapticManager.success()
                            onComplete?()
                            dismiss()
                        }
                    } else if result.isPartialSuccess {
                        // Show partial success - some quotes saved
                        editingQuotes = editingQuotes.filter { quote in
                            result.failures.contains { $0.index == editingQuotes.firstIndex(of: quote) }
                        }
                        HapticManager.warning()
                    } else {
                        saveError = QuoteSaveError.persistenceFailed(
                            NSError(
                                domain: "ExtractionReview",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to save quotes"]
                            )
                        )
                        HapticManager.error()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error
                    HapticManager.error()
                }
            }
        }
    }
}

// MARK: - Add Manual Quote Sheet

/// Sheet for manually adding a quote that the AI missed.
struct AddManualQuoteSheet: View {
    @Environment(\.dismiss) private var dismiss

    let pageId: UUID
    let pageNumber: Int?
    let onAdd: (EditableQuote) -> Void

    @State private var quoteText = ""
    @State private var selectedMarkingType = "underline"
    @State private var marginNote = ""
    @State private var hasAppeared = false
    @State private var quoteTextShakeTrigger = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let markingTypes = [
        "underline",
        "highlight",
        "margin_line",
        "bracket",
        "circle",
        "margin_note",
        "asterisk",
        "question_mark",
        "box"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote Text") {
                    TextEditor(text: $quoteText)
                        .frame(minHeight: 100)
                        .shake(trigger: quoteTextShakeTrigger)
                }

                Section("Marking Type") {
                    Picker("Type", selection: $selectedMarkingType) {
                        ForEach(markingTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Margin Note (Optional)") {
                    TextField("Any note in the margin...", text: $marginNote)
                }

                if let pageNum = pageNumber {
                    Section {
                        HStack {
                            Text("Page Number")
                            Spacer()
                            Text("\(pageNum)")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.light()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        validateAndAddQuote()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }

    private var isQuoteTextValid: Bool {
        !quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func validateAndAddQuote() {
        guard isQuoteTextValid else {
            quoteTextShakeTrigger += 1
            HapticManager.error()
            return
        }
        addQuote()
    }

    private func addQuote() {
        let trimmedText = quoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let quote = EditableQuote(
            pageId: pageId,
            text: trimmedText,
            markingType: selectedMarkingType,
            confidence: nil,
            pageNumber: pageNumber,
            marginNote: marginNote.isEmpty ? nil : marginNote,
            isManual: true
        )

        onAdd(quote)
        HapticManager.light()
        dismiss()
    }
}

// MARK: - Review Summary View

/// Summary view shown before final save.
struct ReviewSummaryView: View {
    let quotes: [EditableQuote]
    let book: Book

    private var quotesByPage: [(pageNumber: Int?, count: Int)] {
        Dictionary(grouping: quotes, by: \.pageNumber)
            .map { (pageNumber: $0.key, count: $0.value.count) }
            .sorted { ($0.pageNumber ?? Int.max) < ($1.pageNumber ?? Int.max) }
    }

    private var markingTypeCounts: [(type: String, count: Int)] {
        Dictionary(grouping: quotes, by: \.markingType)
            .map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Book info
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Color.brand)
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Divider()

            // Quote count
            HStack {
                Image(systemName: "text.quote")
                Text("\(quotes.count) quotes to save")
                    .font(.subheadline)
            }

            // By page
            if !quotesByPage.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("By Page")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    ForEach(quotesByPage, id: \.pageNumber) { item in
                        HStack {
                            if let page = item.pageNumber {
                                Text("Page \(page)")
                            } else {
                                Text("Unknown page")
                            }
                            Spacer()
                            Text("\(item.count)")
                                .foregroundStyle(Color.textSecondary)
                        }
                        .font(.caption)
                    }
                }
            }

            // By marking type
            if !markingTypeCounts.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("By Marking Type")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    ForEach(markingTypeCounts, id: \.type) { item in
                        HStack {
                            Text(item.type.replacingOccurrences(of: "_", with: " ").capitalized)
                            Spacer()
                            Text("\(item.count)")
                                .foregroundStyle(Color.textSecondary)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - Preview

#Preview("Extraction Review") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try? ModelContainer(
        for: Book.self,
        Quote.self,
        CaptureSession.self,
        PageCapture.self,
        configurations: config
    )

    return Group {
        if let container {
            let book = Book(title: "Atomic Habits", author: "James Clear")
            container.mainContext.insert(book)

            let session = CaptureSession(book: book)
            container.mainContext.insert(session)

            ExtractionReviewView(session: session, book: book)
                .modelContainer(container)
        } else {
            Text("Preview unavailable")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Add Manual Quote") {
    AddManualQuoteSheet(
        pageId: UUID(),
        pageNumber: 42,
        onAdd: { _ in }
    )
}
