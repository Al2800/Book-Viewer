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

    @State private var quoteState = ExtractionReviewQuoteState()
    @State private var selectedPage: PageCapture?
    @State private var showingSaveConfirmation = false
    @State private var showingAddQuoteSheet = false
    @State private var showingDiscardAlert = false
    @State private var isSaving = false
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
        !quoteState.isLoading && !isProcessing && quoteState.editingQuotes.isEmpty
    }

    // MARK: - Milestone State

    @StateObject private var milestoneManager = MilestoneManager()
    @Query private var existingQuotes: [Quote]

    /// Completion handler called after successful save
    var onComplete: (() -> Void)?

    // MARK: - Computed Properties

    private var quoteCounts: [UUID: Int] {
        quoteState.quoteCounts
    }

    private var totalQuoteCount: Int {
        quoteState.totalQuoteCount
    }

    private var hasChanges: Bool {
        quoteState.hasChanges
    }

    private var quotesForSelectedPage: [EditableQuote] {
        guard let page = selectedPage else { return [] }
        return quoteState.quotes(for: page.id)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if quoteState.isLoading || isProcessing {
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
                            quoteState.append(quote)
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
        // Prevent swipe-to-dismiss. If the user dismisses this early (for example while processing),
        // the underlying capture view can be left in a "completed" state with no shutter controls.
        .interactiveDismissDisabled(true)
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
            let canSave = !quoteState.editingQuotes.isEmpty && !isSaving
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
            .disabled(quoteState.editingQuotes.isEmpty || isSaving)
        }
    }

    // MARK: - Bindings

    private func bindingForPage(_ page: PageCapture) -> Binding<[EditableQuote]> {
        Binding(
            get: {
                quoteState.quotes(for: page.id)
            },
            set: { newQuotes in
                quoteState.replaceQuotes(for: page.id, with: newQuotes)
            }
        )
    }

    // MARK: - Actions

    private func loadExtractedQuotes() {
        let snapshots = session.captures
            .filter { $0.status == .completed }
            .map(ExtractionReviewPageQuoteSnapshot.init)
        quoteState.loadCompletedQuotes(from: snapshots)
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

    private func processPendingCaptures() async {
        let isConnected = await MainActor.run { networkMonitor.isConnected }
        guard isConnected else {
            await MainActor.run {
                saveError = ExtractionError.networkError(
                    NSError(domain: "ExtractionReview", code: -1009, userInfo: [
                        NSLocalizedDescriptionKey: "No internet connection"
                    ])
                )
            }
            return
        }

        // Fetch marking definitions on the main actor, then snapshot them into Sendable values.
        let markingPrompts: [QuoteExtractionPromptBuilder.MarkingPrompt] = await MainActor.run {
            let markingDescriptor = FetchDescriptor<MarkingDefinition>(
                predicate: #Predicate<MarkingDefinition> { $0.isEnabled }
            )
            let markings = (try? modelContext.fetch(markingDescriptor)) ?? []
            return markings.map { QuoteExtractionPromptBuilder.MarkingPrompt($0) }
        }

        // Mark session as processing on the main actor (SwiftData objects are not concurrency-safe).
        await MainActor.run {
            session.beginProcessing()
            try? modelContext.save()
        }

        // Snapshot pending captures into plain values for background work.
        let pending: [(id: UUID, imageURL: URL?)] = await MainActor.run {
            session.captures
                .filter { $0.status == .pending }
                .map { (id: $0.id, imageURL: $0.imageURL) }
        }

        for item in pending {
            await MainActor.run {
                if let capture = session.captures.first(where: { $0.id == item.id }) {
                    capture.beginProcessing()
                    try? modelContext.save()
                }
            }

            do {
                // Disk IO + image decode off the main actor.
                let image = try await Task.detached(priority: .userInitiated) { () throws -> UIImage in
                    guard let url = item.imageURL else { throw ExtractionError.invalidImage }
                    guard let img = UIImage(contentsOfFile: url.path) else { throw ExtractionError.invalidImage }
                    return img
                }.value

                // Network + image encoding runs off main now that GeminiService is not @MainActor.
                let result = try await geminiService.extractQuotes(from: image, markings: markingPrompts)

                try await MainActor.run {
                    if let capture = session.captures.first(where: { $0.id == item.id }) {
                        try capture.completeExtraction(with: result)
                        session.recordSuccess()
                        try? modelContext.save()
                        loadExtractedQuotes()
                    }
                }
            } catch {
                await MainActor.run {
                    if let capture = session.captures.first(where: { $0.id == item.id }) {
                        capture.failProcessing(error: error.localizedDescription)
                        session.recordFailure()
                        try? modelContext.save()
                        loadExtractedQuotes()
                    }
                }
            }
        }
    }

    private func saveAllQuotes() {
        guard !quoteState.editingQuotes.isEmpty else { return }

        // Capture quote count before saving for milestone check
        let previousCount = existingQuotes.count
        let savedCount = quoteState.editingQuotes.count

        isSaving = true

        Task {
            do {
                let saveService = QuoteSaveService(modelContext: modelContext)

                let extractedQuotes = quoteState.editingQuotes.map { $0.toExtractedQuote() }
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
                        quoteState.replaceAfterPartialSave(with: result.failures)
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
