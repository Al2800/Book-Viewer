import Foundation
import SwiftData

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

/// Checkpoint writes share the quote's ModelContext save, making partial saves
/// crash-safe: a committed quote and its removed review candidate are atomic.
@MainActor
struct ExtractionReviewCheckpointStore {
    let session: CaptureSession
    let modelContext: ModelContext
    var persistChanges: (() throws -> Void)?

    private enum SaveError: LocalizedError {
        case staleCandidate
        var errorDescription: String? {
            "This passage changed or was already saved. Review the remaining draft before trying again."
        }
    }

    private struct Checkpoint: Codable {
        let version: Int
        let sessionID: UUID
        let state: ExtractionReviewQuoteState
    }

    private var anchor: PageCapture? {
        session.reviewCheckpointAnchor
    }

    func restore() throws -> ExtractionReviewQuoteState? {
        guard let anchor, let data = try anchor.loadReviewCheckpointData() else { return nil }
        let checkpoint = try JSONDecoder().decode(Checkpoint.self, from: data)
        let pageIDs = Set(session.captures.map(\.id))
        guard checkpoint.version == 1, checkpoint.sessionID == session.id,
              checkpoint.state.isValid(for: pageIDs) else {
            throw CocoaError(.coderReadCorrupt)
        }
        var state = checkpoint.state
        state.isLoading = false
        return state
    }

    func persist(_ state: ExtractionReviewQuoteState?) throws {
        guard let anchor else { throw CocoaError(.fileNoSuchFile) }
        let previous = anchor.extractedQuotesData
        do {
            let data = try state.map { try JSONEncoder().encode(Checkpoint(version: 1, sessionID: session.id, state: $0)) }
            try anchor.storeReviewCheckpointData(data)
            if let persistChanges { try persistChanges() } else { try modelContext.save() }
        } catch {
            anchor.extractedQuotesData = previous
            throw error
        }
    }

    func save(
        candidates: [EditableQuote],
        state: inout ExtractionReviewQuoteState,
        to book: Book,
        markingDefinition: (EditableQuote) -> MarkingDefinition?
    ) -> BatchSaveResult {
        var saved: [Quote] = []
        var failures: [SaveFailure] = []
        for (index, candidate) in candidates.enumerated() {
            let extracted = candidate.toExtractedQuote(customMarkingDefinition: markingDefinition(candidate))
            guard state.editingQuotes.contains(candidate), state.isSelected(candidate.id) else {
                failures.append(SaveFailure(index: index, extractedQuote: extracted, error: SaveError.staleCandidate))
                continue
            }
            var remaining = state
            remaining.applySaveResult(submittedIDs: [candidate.id], failures: [])
            let service = QuoteSaveService(modelContext: modelContext, persistQuoteChanges: { try persist(remaining) })
            do {
                saved.append(try service.save(extracted, to: book))
                state = remaining
            } catch {
                failures.append(SaveFailure(index: index, extractedQuote: extracted, error: error))
            }
        }
        return BatchSaveResult(savedQuotes: saved, failures: failures, book: book)
    }
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

struct ExtractionReviewQuoteState: Codable, Equatable {
    var editingQuotes: [EditableQuote]
    var isLoading: Bool
    private var deselectedIDs: Set<UUID> = []
    private var loadedPageIDs: Set<UUID> = []

    init(editingQuotes: [EditableQuote] = [], isLoading: Bool = true) {
        self.editingQuotes = editingQuotes
        self.isLoading = isLoading
    }

    func isValid(for pageIDs: Set<UUID>) -> Bool {
        editingQuotes.allSatisfy { pageIDs.contains($0.pageId) }
            && loadedPageIDs.isSubset(of: pageIDs)
            && Set(editingQuotes.map(\.id)).count == editingQuotes.count
    }

    /// Counts all displayed candidates, including excluded ones. Selection and
    /// editing never convert extraction uncertainty into verification.
    var extraCheckingCount: Int {
        editingQuotes.filter { $0.reviewGuidance.needsExtraChecking }.count
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
