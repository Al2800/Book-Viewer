import SwiftUI
import SwiftData

// MARK: - Extraction Review View

/// Main view for reviewing, editing, and confirming extracted quotes before saving.
/// Shows a split view with page thumbnails on the left and quote editor on the right.
struct ExtractionReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(GeminiService.self) private var geminiService
    @Environment(NetworkMonitor.self) private var networkMonitor

    let session: CaptureSession
    let book: Book

    @State private var editingQuotes: [EditableQuote] = []
    @State private var selectedPage: PageCapture?
    @State private var showingSaveConfirmation = false
    @State private var showingAddQuoteSheet = false
    @State private var showingDiscardAlert = false
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var saveError: Error?
    @State private var hasAppeared = false
    @State private var hasStartedProcessing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Processing State

    private var isProcessing: Bool {
        session.captures.contains { $0.status == .processing || $0.status == .pending }
    }

    private var processingProgress: Double {
        let total = session.captures.count
        guard total > 0 else { return 0 }
        let completed = session.captures.filter { $0.status == .completed || $0.status == .failed }.count
        return Double(completed) / Double(total)
    }

    private var hasNoQuotes: Bool {
        !isLoading && !isProcessing && editingQuotes.isEmpty
    }

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
            Group {
                if isLoading || isProcessing {
                    processingView
                } else if hasNoQuotes {
                    noQuotesView
                } else {
                    mainContentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary)
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
            startProcessingIfNeeded()
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

    /// Main content view with page list and quote editor
    private var mainContentView: some View {
        HStack(spacing: Spacing.md) {
            // Left: Page thumbnails
            PageListView(
                session: session,
                selection: $selectedPage,
                quoteCounts: quoteCounts
            )
            .frame(maxHeight: .infinity)
            // Right: Quote editor for selected page
            if let page = selectedPage {
                PageQuoteEditor(
                    page: page,
                    quotes: bindingForPage(page),
                    onAddManualQuote: {
                        showingAddQuoteSheet = true
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                noSelectionView
            }
        }
        .padding(Spacing.md)
    }

    /// Processing state view with progress
    private var processingView: some View {
        VStack {
            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)

                VStack(spacing: Spacing.sm) {
                    Text("Processing Pages")
                        .font(.headline)

                    Text("Extracting quotes from your captured pages...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Progress bar
                    ProgressView(value: processingProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                        .padding(.top, Spacing.md)

                    let completedCount = session.captures.filter { $0.status == .completed }.count
                    let totalCount = session.captures.count
                    Text("\(completedCount) of \(totalCount) pages complete")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.xl)
            .paperCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            // Poll for updates while processing
            while isProcessing {
                try? await Task.sleep(for: .milliseconds(500))
                loadExtractedQuotes()
            }
        }
    }

    /// Empty state when no quotes found
    private var noQuotesView: some View {
        ContentUnavailableView {
            Label("No Quotes Found", systemImage: "text.quote")
        } description: {
            Text("No marked passages were detected in the captured pages. You can add quotes manually or try recapturing with clearer markings.")
        } actions: {
            HStack(spacing: Spacing.md) {
                Button {
                    HapticManager.light()
                    showingAddQuoteSheet = true
                } label: {
                    Label("Add Quote Manually", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    onComplete?()
                    dismiss()
                } label: {
                    Text("Close")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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
            let canSave = !editingQuotes.isEmpty && !isSaving
            Button {
                HapticManager.medium()
                showingSaveConfirmation = true
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Save All")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(canSave ? Color.brand : Color.textSecondary)
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
        // Load extracted quotes from each completed page capture
        var loadedQuotes: [EditableQuote] = []

        for capture in session.captures where capture.status == .completed {
            let extractedData = capture.loadExtractedQuotes()

            for data in extractedData {
                let editableQuote = EditableQuote(
                    pageId: capture.id,
                    text: data.text,
                    markingType: data.markingType,
                    confidence: data.confidence,
                    pageNumber: data.pageNumber ?? capture.detectedPageNumber,
                    marginNote: data.marginNote,
                    isManual: false
                )
                loadedQuotes.append(editableQuote)
            }
        }

        // Only update if quotes have changed to avoid unnecessary redraws
        // Compare by IDs since EditableQuote generates new UUIDs on each load
        let loadedIds = Set(loadedQuotes.map { "\($0.pageId)-\($0.text.prefix(50))" })
        let existingIds = Set(editingQuotes.map { "\($0.pageId)-\($0.text.prefix(50))" })
        if loadedIds != existingIds {
            editingQuotes = loadedQuotes
        }

        isLoading = false
    }

    private func selectFirstPage() {
        if selectedPage == nil {
            selectedPage = session.captures
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .first
        }
    }

    private func startProcessingIfNeeded() {
        guard !hasStartedProcessing else { return }
        let hasPending = session.captures.contains { $0.status == .pending }
        guard hasPending else { return }

        hasStartedProcessing = true

        Task {
            await processPendingCaptures()
        }
    }

    @MainActor
    private func processPendingCaptures() async {
        guard networkMonitor.isConnected else {
            saveError = ExtractionError.networkError(
                NSError(domain: "ExtractionReview", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "No internet connection"
                ])
            )
            return
        }

        session.beginProcessing()

        let markingDescriptor = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate<MarkingDefinition> { $0.isEnabled }
        )
        let markings = (try? modelContext.fetch(markingDescriptor)) ?? []

        for capture in session.captures where capture.status == .pending {
            capture.beginProcessing()

            do {
                guard let image = capture.loadFullImage() else {
                    throw ExtractionError.invalidImage
                }

                let result = try await geminiService.extractQuotes(from: image, markings: markings)

                capture.storeExtractedQuotes(result.quotes)
                capture.completeProcessing(
                    quoteCount: result.quoteCount,
                    avgConfidence: result.averageConfidence,
                    pageNumber: result.pageNumber
                )
                session.recordSuccess()

            } catch {
                capture.failProcessing(error: error.localizedDescription)
                session.recordFailure()
            }

            try? modelContext.save()
            loadExtractedQuotes()
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

    Group {
        if let container {
            let (book, session): (Book, CaptureSession) = {
                let book = Book(title: "Atomic Habits", author: "James Clear")
                container.mainContext.insert(book)

                let session = CaptureSession(book: book)
                container.mainContext.insert(session)
                return (book, session)
            }()

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
