import SwiftUI
import SwiftData

// MARK: - Extraction Review View

/// Main view for reviewing, editing, and confirming extracted quotes before saving.
/// Shows a split view with page thumbnails on the left and quote editor on the right.
struct ExtractionReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    let session: CaptureSession
    let book: Book

    @State private var quoteState = ExtractionReviewQuoteState()
    @State private var selectedPage: PageCapture?
    @State private var showingAddQuoteSheet = false
    @State private var showingDiscardAlert = false
    @State private var isSaving = false
    @State private var saveError: Error?
    @State private var pendingDuplicateChecks: [QuoteSaveService.PreSaveCheckResult] = []
    @State private var approvedQuotes: [ExtractedQuote] = []
    @State private var currentDuplicateCheck: DuplicateCheckItem?
    @State private var hasAppeared = false
    @State private var hasStartedProcessing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    private var processingSummary: ExtractionReviewProcessingSummary {
        ExtractionReviewProcessingSummary(
            isQuoteStateLoading: quoteState.isLoading,
            isProcessing: isProcessing,
            totalQuoteCount: quoteState.totalQuoteCount,
            captures: session.captures.map(ExtractionReviewCaptureStatusSnapshot.init)
        )
    }

    private var quoteExtractor: any QuoteExtracting {
        QuoteExtractionPipeline.live(authService: authService)
    }

    // MARK: - Milestone State

    @StateObject private var milestoneManager = MilestoneManager()
    @Query private var existingQuotes: [Quote]
    @Query private var markingDefinitions: [MarkingDefinition]

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
                } else if processingSummary.hasExtractionFailures {
                    extractionFailureView
                } else if processingSummary.hasNoQuotes {
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
        .sheet(item: $currentDuplicateCheck, onDismiss: advanceDuplicateReview) { item in
                DuplicateWarningSheet(
                    duplicates: item.check.duplicates,
                    newQuoteText: item.check.extractedQuote.text,
                    book: book,
                    onSaveAnyway: {
                        approvedQuotes.append(item.check.extractedQuote)
                    },
                    onCancel: {}
                )
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
    @ViewBuilder
    private var mainContentView: some View {
        if usesSideBySideReviewLayout {
            HStack(spacing: Spacing.md) {
                pageList(layout: .vertical)
                editorContent(imageHeight: 260, scrollsQuotesIndependently: true)
            }
            .padding(Spacing.md)
        } else {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    pageList(layout: .horizontal)
                    editorContent(
                        imageHeight: dynamicTypeSize.isAccessibilitySize ? 150 : 180,
                        scrollsQuotesIndependently: false
                    )
                }
                .padding(Spacing.sm)
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionReviewScrollView)
        }
    }

    private var usesSideBySideReviewLayout: Bool {
        horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
    }

    private func pageList(layout: PageListLayout) -> some View {
        PageListView(
            session: session,
            selection: $selectedPage,
            quoteCounts: quoteCounts,
            layout: layout
        )
    }

    @ViewBuilder
    private func editorContent(imageHeight: CGFloat, scrollsQuotesIndependently: Bool) -> some View {
        if let page = selectedPage {
            if scrollsQuotesIndependently {
                PageQuoteEditor(
                    page: page,
                    quotes: bindingForPage(page),
                    onAddManualQuote: {
                        showingAddQuoteSheet = true
                    },
                    imageHeight: imageHeight,
                    scrollsQuotesIndependently: true
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PageQuoteEditor(
                    page: page,
                    quotes: bindingForPage(page),
                    onAddManualQuote: {
                        showingAddQuoteSheet = true
                    },
                    imageHeight: imageHeight,
                    scrollsQuotesIndependently: false
                )
                .frame(maxWidth: .infinity)
            }
        } else {
            noSelectionView
        }
    }

    /// Processing state view with progress
    private var processingView: some View {
        ExtractionReviewProcessingView(
            progress: processingProgress,
            completedCount: session.captures.filter { $0.status == .completed }.count,
            totalCount: session.captures.count,
            isProcessing: isProcessing,
            onPoll: loadExtractedQuotes
        )
    }

    /// Empty state when no quotes found
    private var noQuotesView: some View {
        ExtractionReviewNoQuotesView(
            onAddManualQuote: addManualQuote,
            onClose: closeReview
        )
    }

    private var extractionFailureView: some View {
        ExtractionReviewFailureView(
            primaryFailureMessage: processingSummary.primaryFailureMessage,
            onAddManualQuote: addManualQuote,
            onClose: closeReview
        )
    }

    private var noSelectionView: some View {
        ExtractionReviewNoSelectionView()
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
            .accessibilityIdentifier(AccessibilityIdentifiers.Capture.cancelButton)
        }

        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("\(totalQuoteCount) Quotes")
                    .font(.headline)
                    .contentTransition(.numericText())
                Text(book.title)
                    .font(.authorNameSmall)
                    .foregroundStyle(Color.textSecondary)
            }
            .opacity(hasAppeared ? 1 : 0)
        }

        ToolbarItem(placement: .confirmationAction) {
            let canSave = !quoteState.editingQuotes.isEmpty && !isSaving
            Button {
                HapticManager.medium()
                saveAllQuotes()
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

    private func addManualQuote() {
        HapticManager.light()
        showingAddQuoteSheet = true
    }

    private func closeReview() {
        onComplete?()
        dismiss()
    }

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
        let processor = ExtractionReviewProcessor(
            modelContext: modelContext,
            session: session,
            quoteExtractor: quoteExtractor
        )
        await processor.processPendingCaptures(onCaptureChanged: loadExtractedQuotes)
    }

    private func saveAllQuotes() {
        guard !quoteState.editingQuotes.isEmpty else { return }

        let saveService = QuoteSaveService(modelContext: modelContext)
        let extractedQuotes = quoteState.editingQuotes.map { quote in
            quote.toExtractedQuote(
                customMarkingDefinition: customMarkingDefinition(for: quote)
            )
        }
        let checks = saveService.checkBatchForDuplicates(extractedQuotes, to: book)

        approvedQuotes = checks.filter { !$0.hasDuplicates }.map(\.extractedQuote)
        pendingDuplicateChecks = checks.filter(\.hasDuplicates)

        if pendingDuplicateChecks.isEmpty {
            persistApprovedQuotes()
        } else {
            currentDuplicateCheck = DuplicateCheckItem(check: pendingDuplicateChecks.removeFirst())
        }
    }

    /// Presents the next duplicate warning, or persists once all duplicates are reviewed.
    private func advanceDuplicateReview() {
        if !pendingDuplicateChecks.isEmpty {
            currentDuplicateCheck = DuplicateCheckItem(check: pendingDuplicateChecks.removeFirst())
        } else {
            persistApprovedQuotes()
        }
    }

    private func persistApprovedQuotes() {
        let quotesToSave = approvedQuotes
        approvedQuotes = []

        guard !quotesToSave.isEmpty else {
            // User skipped every flagged duplicate; leave the editor untouched.
            HapticManager.warning()
            return
        }

        // Capture quote count before saving for milestone check
        let previousCount = existingQuotes.count
        let savedCount = quotesToSave.count

        isSaving = true

        Task {
            let saveService = QuoteSaveService(modelContext: modelContext)
            let result = saveService.saveMultiple(quotesToSave, to: book)

            await MainActor.run {
                isSaving = false

                if result.isFullSuccess {
                    session.deleteImageFiles()
                    try? modelContext.save()

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
        }
    }

    private func customMarkingDefinition(for quote: EditableQuote) -> MarkingDefinition? {
        guard let definitionID = quote.customMarkingDefinitionID else { return nil }
        return markingDefinitions.first { $0.id == definitionID }
    }
}

// MARK: - Duplicate Check Item

/// Identifiable wrapper so duplicate checks can drive a `sheet(item:)` one at a time.
private struct DuplicateCheckItem: Identifiable {
    let id = UUID()
    let check: QuoteSaveService.PreSaveCheckResult
}
