import Foundation

struct ExtractionReviewPageQuoteSnapshot {
    let pageId: UUID
    let detectedPageNumber: Int?
    let quotes: [ExtractedQuoteData]
}

extension ExtractionReviewPageQuoteSnapshot {
    init(capture: PageCapture) {
        self.init(
            pageId: capture.id,
            detectedPageNumber: capture.detectedPageNumber,
            quotes: capture.loadExtractedQuotes()
        )
    }
}

struct ExtractionReviewCaptureStatusSnapshot {
    let pageId: UUID
    let status: PageCapture.CaptureStatus
    let errorMessage: String?
    let quoteCount: Int
}

extension ExtractionReviewCaptureStatusSnapshot {
    init(capture: PageCapture) {
        self.init(
            pageId: capture.id,
            status: capture.status,
            errorMessage: capture.errorMessage,
            quoteCount: capture.extractedQuoteCount
        )
    }
}

struct ExtractionReviewProcessingSummary {
    let isQuoteStateLoading: Bool
    let isProcessing: Bool
    let totalQuoteCount: Int
    let captures: [ExtractionReviewCaptureStatusSnapshot]

    var failedPageCount: Int {
        captures.filter { $0.status == .failed }.count
    }

    var hasExtractionFailures: Bool {
        !isQuoteStateLoading && !isProcessing && totalQuoteCount == 0 && failedPageCount > 0
    }

    var hasNoQuotes: Bool {
        !isQuoteStateLoading && !isProcessing && totalQuoteCount == 0 && !hasExtractionFailures
    }

    var primaryFailureMessage: String? {
        captures
            .filter { $0.status == .failed }
            .compactMap(\.errorMessage)
            .first
    }
}

struct ExtractionReviewQuoteState {
    var editingQuotes: [EditableQuote]
    var isLoading: Bool
    private var deselectedIDs: Set<UUID> = []
    private var loadedPageIDs: Set<UUID> = []

    init(editingQuotes: [EditableQuote] = [], isLoading: Bool = true) {
        self.editingQuotes = editingQuotes
        self.isLoading = isLoading
    }

    var quoteCounts: [UUID: Int] {
        Dictionary(grouping: editingQuotes, by: \.pageId)
            .mapValues { $0.count }
    }

    var totalQuoteCount: Int {
        editingQuotes.count
    }

    var selectedQuotes: [EditableQuote] {
        editingQuotes.filter { !deselectedIDs.contains($0.id) }
    }

    func isSelected(_ id: UUID) -> Bool {
        editingQuotes.contains { $0.id == id } && !deselectedIDs.contains(id)
    }

    mutating func setSelected(_ selected: Bool, id: UUID) {
        guard editingQuotes.contains(where: { $0.id == id }) else { return }
        if selected {
            deselectedIDs.remove(id)
        } else {
            deselectedIDs.insert(id)
        }
    }

    var hasChanges: Bool {
        !editingQuotes.isEmpty
    }

    func quotes(for pageId: UUID) -> [EditableQuote] {
        editingQuotes.filter { $0.pageId == pageId }
    }

    mutating func append(_ quote: EditableQuote) {
        editingQuotes.append(quote)
    }

    mutating func replaceQuotes(for pageId: UUID, with newQuotes: [EditableQuote]) {
        editingQuotes.removeAll { $0.pageId == pageId }
        editingQuotes.append(contentsOf: newQuotes)
    }

    /// Failure indices belong to the submitted batch, not the full review array.
    /// Remove only confirmed successes; retain excluded/skipped candidates and failures.
    mutating func applySaveResult(submittedIDs: [UUID], failures: [SaveFailure]) {
        let failedIndices = Set(failures.map(\.index))
        let successfulIDs = Set(submittedIDs.enumerated().compactMap { index, id in
            failedIndices.contains(index) ? nil : id
        })
        editingQuotes.removeAll { successfulIDs.contains($0.id) }
        deselectedIDs.subtract(successfulIDs)
    }

    mutating func loadCompletedQuotes(from snapshots: [ExtractionReviewPageQuoteSnapshot]) {
        // A completed page is imported once per review. Polling or another page
        // completing must not resurrect saved/deleted candidates or overwrite edits.
        let newSnapshots = snapshots.filter { !loadedPageIDs.contains($0.pageId) }
        let loadedQuotes = newSnapshots.flatMap { snapshot in
            snapshot.quotes.map { data in
                EditableQuote(
                    pageId: snapshot.pageId,
                    text: data.text,
                    markingType: data.markingType,
                    confidence: data.confidence,
                    pageNumber: data.pageNumber ?? snapshot.detectedPageNumber,
                    marginNote: data.marginNote,
                    isManual: false,
                    extractionSource: data.extractionSource,
                    customMarkingDefinitionID: data.customMarkingDefinitionID,
                    customMarkingDisplayName: data.customMarkingDisplayName,
                    boundingBox: data.normalizedBoundingBox,
                    suggestedTags: data.suggestedTags
                )
            }
        }

        editingQuotes.append(contentsOf: loadedQuotes)
        loadedPageIDs.formUnion(newSnapshots.map(\.pageId))
        isLoading = false
    }
}
