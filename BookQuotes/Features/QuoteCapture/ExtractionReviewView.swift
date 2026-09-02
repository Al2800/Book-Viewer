import SwiftUI
import SwiftData

// MARK: - Extraction Review View

/// Main view for reviewing, editing, and confirming extracted quotes before saving.
/// Stacked Passages sheet: page groups, quote cards, then add-manually.
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
    @State private var showingAIConsent = false
    @State private var pageToView: PageCapture?
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

    private var totalQuoteCount: Int {
        quoteState.totalQuoteCount
    }

    private var hasChanges: Bool {
        quoteState.hasChanges
    }

    private var orderedPages: [PageCapture] {
        session.captures.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var showsPageHeaders: Bool {
        session.captures.count > 1
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
            .navigationTitle("Passages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ExtractionReviewPassagesToolbar(
                    bookTitle: book.title,
                    hasAppeared: hasAppeared,
                    canSave: !quoteState.editingQuotes.isEmpty && !isSaving,
                    isSaving: isSaving,
                    onCancel: {
                        HapticManager.light()
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    },
                    onSave: {
                        HapticManager.medium()
                        saveAllQuotes()
                    }
                )
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
                if let page = selectedPage ?? orderedPages.last {
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
        .sheet(isPresented: $showingAIConsent) {
            AIProcessingConsentView { _ in
                showingAIConsent = false
                startProcessingIfNeeded()
            }
            .interactiveDismissDisabled()
        }
        // Prevent swipe-to-dismiss. If the user dismisses this early (for example while processing),
        // the underlying capture view can be left in a "completed" state with no shutter controls.
        .fullScreenCover(item: $pageToView) { page in
            FullImageViewer(page: page)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            loadExtractedQuotes()
            selectFirstPage()
            startProcessingIfNeeded()
            // Trigger entrance animation
            guard !UITestConfiguration.isUITesting, !reduceMotion else {
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

    /// Stacked Passages list grouped by page.
    @ViewBuilder
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(orderedPages) { page in
                    if showsPageHeaders {
                        ExtractionReviewPageGroupHeader(page: page) {
                            pageToView = page
                        }
                    }

                    ForEach(quoteState.quotes(for: page.id)) { quote in
                        if let index = quoteState.editingQuotes.firstIndex(where: { $0.id == quote.id }) {
                            QuoteEditRow(
                                quote: $quoteState.editingQuotes[index],
                                onDelete: {
                                    deleteQuote(quote)
                                }
                            )
                        }
                    }
                }

                ExtractionReviewAddPassageRow {
                    HapticManager.light()
                    if selectedPage == nil {
                        selectedPage = orderedPages.last
                    }
                    showingAddQuoteSheet = true
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Capture.extractionReviewScrollView)
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
            onRetry: retryFailedExtractions,
            onUseOnDevice: retryFailedExtractionsOnDevice,
            onAddManualQuote: addManualQuote,
            onClose: closeReview
        )
    }

    // MARK: - Bindings

    private func deleteQuote(_ quote: EditableQuote) {
        quoteState.editingQuotes.removeAll { $0.id == quote.id }
        HapticManager.light()
    }

    // MARK: - Actions

    private func addManualQuote() {
        HapticManager.light()
        if selectedPage == nil {
            selectedPage = orderedPages.last
        }
        showingAddQuoteSheet = true
    }

    private func closeReview() {
        dismiss()
    }

    private func retryFailedExtractions() {
        HapticManager.medium()
        session.retryFailedCaptures()
        hasStartedProcessing = false
        try? modelContext.save()
        startProcessingIfNeeded()
    }

    private func retryFailedExtractionsOnDevice() {
        HapticManager.medium()
        session.retryFailedCaptures()
        hasStartedProcessing = true
        try? modelContext.save()

        Task {
            await processPendingCaptures(using: OnDeviceQuoteExtractor())
        }
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

        if TestFlightAIBypassPolicy.shouldOfferConsent(
            isAuthenticated: authService.isAuthenticated,
            hasCurrentConsent: AIProcessingConsentStore.shared.hasCurrentConsent
        ) {
            showingAIConsent = true
            return
        }

        hasStartedProcessing = true

        Task {
            await processPendingCaptures()
        }
    }

    private func processPendingCaptures(using extractorOverride: (any QuoteExtracting)? = nil) async {
        let effectiveExtractor: any QuoteExtracting
        if let extractorOverride {
            effectiveExtractor = extractorOverride
        } else {
            effectiveExtractor = quoteExtractor
        }

        let processor = ExtractionReviewProcessor(
            modelContext: modelContext,
            session: session,
            quoteExtractor: effectiveExtractor
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
