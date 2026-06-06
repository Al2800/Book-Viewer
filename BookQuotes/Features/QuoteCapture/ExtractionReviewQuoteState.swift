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

    var hasExtractionFailures: Bool {
        !isQuoteStateLoading && !isProcessing && totalQuoteCount == 0 && captures.contains { $0.status == .failed }
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

    mutating func replaceAfterPartialSave(with failures: [SaveFailure]) {
        editingQuotes = editingQuotes.filter { quote in
            failures.contains { $0.index == editingQuotes.firstIndex(of: quote) }
        }
    }

    mutating func loadCompletedQuotes(from snapshots: [ExtractionReviewPageQuoteSnapshot]) {
        let loadedQuotes = snapshots.flatMap { snapshot in
            snapshot.quotes.map { data in
                EditableQuote(
                    pageId: snapshot.pageId,
                    text: data.text,
                    markingType: data.markingType,
                    confidence: data.confidence,
                    pageNumber: data.pageNumber ?? snapshot.detectedPageNumber,
                    marginNote: data.marginNote,
                    isManual: false
                )
            }
        }

        if identitySet(for: loadedQuotes) != identitySet(for: editingQuotes) {
            editingQuotes = loadedQuotes
        }

        isLoading = false
    }

    private func identitySet(for quotes: [EditableQuote]) -> Set<String> {
        Set(quotes.map { "\($0.pageId)-\($0.text.prefix(50))" })
    }
}
