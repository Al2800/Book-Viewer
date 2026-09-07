import XCTest
import SwiftData

@testable import BookQuotes

final class ExtractionReviewQuoteStateTests: XCTestCase {
    func testExtraCheckingCountsAllCandidatesWithoutChangingSelectionOrVerifyingEdits() {
        let page = UUID()
        let scores: [Double?] = [nil, .nan, -.infinity, -0.1, 1.1, 0.49, 0.5, 0.79, 0.8, 1]
        var state = ExtractionReviewQuoteState(editingQuotes: scores.map {
            EditableQuote(pageId: page, text: "Source", markingType: "underline", confidence: $0)
        }, isLoading: false)
        state.append(EditableQuote(pageId: page, text: "Manual", markingType: "underline", confidence: 0, isManual: true))
        XCTAssertEqual(state.extraCheckingCount, 8)
        XCTAssertEqual(state.selectedQuotes.count, 11)
        let first = state.editingQuotes[0].id
        state.setSelected(false, id: first)
        state.editingQuotes[0].isModified = true
        state.editingQuotes[0].text = "Corrected"
        XCTAssertEqual(state.extraCheckingCount, 8)
        XCTAssertEqual(state.selectedQuotes.count, 10)
        state.applySaveResult(submittedIDs: [first], failures: [])
        XCTAssertEqual(state.extraCheckingCount, 7)
    }


    func testSelectionDefaultsToAllAndDoesNotDeleteExcludedCandidates() {
        let a = EditableQuote(pageId: UUID(), text: "First", markingType: "underline")
        let b = EditableQuote(pageId: UUID(), text: "Second", markingType: "highlight")
        var state = ExtractionReviewQuoteState(editingQuotes: [a, b])
        XCTAssertEqual(state.selectedQuotes.map(\.id), [a.id, b.id])
        state.setSelected(false, id: a.id)
        XCTAssertEqual(state.selectedQuotes.map(\.id), [b.id])
        XCTAssertEqual(state.totalQuoteCount, 2)
        state.setSelected(false, id: b.id)
        XCTAssertTrue(state.selectedQuotes.isEmpty)
        XCTAssertTrue(state.hasChanges)
        state.setSelected(true, id: a.id)
        XCTAssertEqual(state.selectedQuotes.map(\.id), [a.id])
    }

    func testPartialSaveUsesSubmittedIdentityOrderAndPreservesExcludedAndSkippedCandidates() {
        let page = UUID()
        let excluded = EditableQuote(pageId: page, text: "Excluded", markingType: "underline")
        let failed = EditableQuote(pageId: page, text: "Duplicate approved later", markingType: "underline")
        let saved = EditableQuote(pageId: page, text: "Nonduplicate saved first", markingType: "underline")
        let skipped = EditableQuote(pageId: page, text: "Duplicate skipped", markingType: "underline")
        var state = ExtractionReviewQuoteState(editingQuotes: [excluded, failed, saved, skipped])
        state.setSelected(false, id: excluded.id)
        let failure = SaveFailure(index: 1, extractedQuote: failed.toExtractedQuote(), error: QuoteSaveError.invalidQuoteData("Test failure"))
        state.applySaveResult(submittedIDs: [saved.id, failed.id], failures: [failure])
        XCTAssertEqual(state.editingQuotes.map(\.id), [excluded.id, failed.id, skipped.id])
        XCTAssertEqual(state.selectedQuotes.map(\.id), [failed.id, skipped.id])
        XCTAssertFalse(state.isSelected(excluded.id))
    }

    func testFullSaveFailurePreservesSelectionAndTextForRetry() {
        let quote = EditableQuote(pageId: UUID(), text: "Keep this edit", markingType: "underline")
        var state = ExtractionReviewQuoteState(editingQuotes: [quote])
        state.applySaveResult(submittedIDs: [quote.id], failures: [
            SaveFailure(index: 0, extractedQuote: quote.toExtractedQuote(), error: QuoteSaveError.invalidQuoteData("Test failure"))
        ])
        XCTAssertEqual(state.selectedQuotes, [quote])
    }

    func testPollingNewPagesPreservesEditsSelectionManualAndDeletedCandidates() {
        let first = snapshot(page: UUID(), text: "Original")
        let second = snapshot(page: UUID(), text: "Second page")
        var state = ExtractionReviewQuoteState()
        state.loadCompletedQuotes(from: [first])
        let firstID = state.editingQuotes[0].id
        state.editingQuotes[0].text = "Corrected by reader"
        state.setSelected(false, id: firstID)
        let manual = EditableQuote(pageId: first.pageId, text: "Manual", markingType: "underline", isManual: true)
        state.append(manual)
        state.loadCompletedQuotes(from: [first, second])
        XCTAssertEqual(state.editingQuotes.map(\.text), ["Corrected by reader", "Manual", "Second page"])
        XCTAssertFalse(state.isSelected(firstID))
        XCTAssertTrue(state.isSelected(manual.id))
        state.editingQuotes.removeAll { $0.id == firstID }
        state.loadCompletedQuotes(from: [first, second])
        XCTAssertEqual(state.editingQuotes.map(\.text), ["Manual", "Second page"])
    }

    func testPollingDoesNotResurrectSuccessfullySavedCandidates() {
        let page = snapshot(page: UUID(), text: "Already saved")
        var state = ExtractionReviewQuoteState()
        state.loadCompletedQuotes(from: [page])
        state.applySaveResult(submittedIDs: state.editingQuotes.map(\.id), failures: [])
        state.loadCompletedQuotes(from: [page])
        XCTAssertTrue(state.editingQuotes.isEmpty)
    }

    private func snapshot(page: UUID, text: String) -> ExtractionReviewPageQuoteSnapshot {
        ExtractionReviewPageQuoteSnapshot(pageId: page, detectedPageNumber: 42, quotes: [
            ExtractedQuoteData(text: text, pageNumber: nil, marginNote: nil, markingType: "underline", confidence: 0.8)
        ])
    }

    func testLoadingPageSnapshotsMapsExtractedQuotesIntoEditableReviewState() {
        let firstPageId = UUID()
        let secondPageId = UUID()
        var state = ExtractionReviewQuoteState()

        state.loadCompletedQuotes(from: [
            ExtractionReviewPageQuoteSnapshot(
                pageId: firstPageId,
                detectedPageNumber: 42,
                quotes: [
                    ExtractedQuoteData(
                        text: "The obstacle is the way.",
                        pageNumber: nil,
                        marginNote: "starred",
                        markingType: "underline",
                        confidence: 0.91,
                        extractionSource: .modelAssisted,
                        customMarkingDefinitionID: UUID(uuidString: "D8FD4363-3572-4B46-8A7B-47680D4B3D76"),
                        customMarkingDisplayName: "Follow Up",
                        boundingBox: [0.1, 0.2, 0.8, 0.05],
                        suggestedTags: ["stoicism", "resilience"]
                    )
                ]
            ),
            ExtractionReviewPageQuoteSnapshot(
                pageId: secondPageId,
                detectedPageNumber: nil,
                quotes: [
                    ExtractedQuoteData(
                        text: "What gets measured gets managed.",
                        pageNumber: 12,
                        marginNote: nil,
                        markingType: "highlight",
                        confidence: 0.82
                    )
                ]
            )
        ])

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.totalQuoteCount, 2)
        XCTAssertEqual(state.quoteCounts[firstPageId], 1)
        XCTAssertEqual(state.quoteCounts[secondPageId], 1)

        let firstQuote = state.quotes(for: firstPageId).first
        XCTAssertEqual(firstQuote?.text, "The obstacle is the way.")
        XCTAssertEqual(firstQuote?.pageNumber, 42)
        XCTAssertEqual(firstQuote?.marginNote, "starred")
        XCTAssertEqual(firstQuote?.markingType, "underline")
        XCTAssertEqual(firstQuote?.confidence, 0.91)
        XCTAssertEqual(firstQuote?.isManual, false)
        XCTAssertEqual(firstQuote?.extractionSource, .modelAssisted)
        XCTAssertEqual(firstQuote?.customMarkingDisplayName, "Follow Up")
        XCTAssertEqual(firstQuote?.boundingBox, CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.05))
        XCTAssertEqual(firstQuote?.suggestedTags, ["stoicism", "resilience"])

        let secondQuote = state.quotes(for: secondPageId).first
        XCTAssertEqual(secondQuote?.pageNumber, 12)
    }

    func testManualEditableQuoteRecordsManualExtractionSource() {
        let quote = EditableQuote(
            pageId: UUID(),
            text: "Manually added quote",
            markingType: "underline",
            isManual: true
        )

        XCTAssertEqual(quote.extractionSource, .manual)
    }

    func testReplacingQuotesForPagePreservesOtherPagesAndCurrentAppendOrder() {
        let firstPageId = UUID()
        let secondPageId = UUID()
        let firstPageQuote = EditableQuote(pageId: firstPageId, text: "First", markingType: "underline")
        let secondPageQuote = EditableQuote(pageId: secondPageId, text: "Second", markingType: "highlight")
        let replacementQuote = EditableQuote(pageId: firstPageId, text: "Replacement", markingType: "bracket")
        var state = ExtractionReviewQuoteState(editingQuotes: [firstPageQuote, secondPageQuote])

        state.replaceQuotes(for: firstPageId, with: [replacementQuote])

        XCTAssertEqual(state.totalQuoteCount, 2)
        XCTAssertEqual(state.quotes(for: secondPageId).map(\.text), ["Second"])
        XCTAssertEqual(state.quotes(for: firstPageId).map(\.text), ["Replacement"])
        XCTAssertEqual(state.editingQuotes.map(\.text), ["Second", "Replacement"])
    }

    func testProcessingSummaryTreatsFailedPagesAsExtractionFailureNotNoQuotes() {
        let failedPage = ExtractionReviewCaptureStatusSnapshot(
            pageId: UUID(),
            status: .failed,
            errorMessage: "Please sign in to continue",
            quoteCount: 0
        )

        let summary = ExtractionReviewProcessingSummary(
            isQuoteStateLoading: false,
            isProcessing: false,
            totalQuoteCount: 0,
            captures: [failedPage]
        )

        XCTAssertTrue(summary.hasExtractionFailures)
        XCTAssertFalse(summary.hasNoQuotes)
        XCTAssertEqual(summary.primaryFailureMessage, "Please sign in to continue")
    }

    func testMixedExtractionSuccessStillReportsFailedPagesForRecovery() {
        let summary = ExtractionReviewProcessingSummary(
            isQuoteStateLoading: false,
            isProcessing: false,
            totalQuoteCount: 2,
            captures: [
                ExtractionReviewCaptureStatusSnapshot(pageId: UUID(), status: .completed, errorMessage: nil, quoteCount: 2),
                ExtractionReviewCaptureStatusSnapshot(pageId: UUID(), status: .failed, errorMessage: "Network unavailable", quoteCount: 0)
            ]
        )
        XCTAssertFalse(summary.hasExtractionFailures, "Mixed success uses the review list, not the empty failure screen")
        XCTAssertEqual(summary.failedPageCount, 1, "Successful passages must not hide a failed page")
        XCTAssertFalse(summary.hasNoQuotes)
    }

    func testProcessingSummaryTreatsCompletedEmptyPagesAsNoQuotes() {
        let completedPage = ExtractionReviewCaptureStatusSnapshot(
            pageId: UUID(),
            status: .completed,
            errorMessage: nil,
            quoteCount: 0
        )

        let summary = ExtractionReviewProcessingSummary(
            isQuoteStateLoading: false,
            isProcessing: false,
            totalQuoteCount: 0,
            captures: [completedPage]
        )

        XCTAssertFalse(summary.hasExtractionFailures)
        XCTAssertTrue(summary.hasNoQuotes)
        XCTAssertNil(summary.primaryFailureMessage)
    }
}

final class ExtractionReviewCheckpointTests: SwiftDataTestCase {
    private func fixture() throws -> (CaptureSession, PageCapture, Book) {
        let book = Book(title: "Checkpoint book", author: "Reader")
        let session = CaptureSession(book: book)
        let page = PageCapture(imagePath: "captures/test/source.jpg", session: session)
        modelContext.insert(book)
        modelContext.insert(session)
        modelContext.insert(page)
        session.addCapture(page)
        page.storeExtractedQuotes([ExtractedQuoteData(text: "Original source passage", pageNumber: 12, marginNote: nil, markingType: "underline", confidence: 0.7)])
        page.completeProcessing(quoteCount: 1, avgConfidence: 0.7, pageNumber: 12)
        session.resumeReviewProcessing()
        try modelContext.save()
        return (session, page, book)
    }

    func testNewContextRestoresEditsSelectionManualEntriesAndOriginalSourceBytes() throws {
        let (session, page, _) = try fixture()
        let original = page.extractedQuotesData
        var state = ExtractionReviewQuoteState()
        state.loadCompletedQuotes(from: [.init(capture: page)])
        state.editingQuotes[0].text = "Corrected words"
        state.editingQuotes[0].isModified = true
        state.editingQuotes[0].marginNote = "Reader correction"
        state.editingQuotes[0].pageNumber = 13
        state.editingQuotes[0].customMarkingDefinitionID = UUID()
        state.editingQuotes[0].customMarkingDisplayName = "My marking"
        state.editingQuotes[0].boundingBox = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.1)
        state.editingQuotes[0].suggestedTags = ["memory", "reading"]
        state.setSelected(false, id: state.editingQuotes[0].id)
        state.append(EditableQuote(pageId: page.id, text: "Manual addition", markingType: "underline", isManual: true))
        let store = ExtractionReviewCheckpointStore(session: session, modelContext: modelContext)
        try store.persist(state)

        let fresh = ModelContext(modelContainer)
        let reloaded = try XCTUnwrap(fresh.fetch(FetchDescriptor<CaptureSession>()).first)
        var restored = try XCTUnwrap(ExtractionReviewCheckpointStore(session: reloaded, modelContext: fresh).restore())
        XCTAssertEqual(restored, state)
        restored.loadCompletedQuotes(from: reloaded.captures.map(ExtractionReviewPageQuoteSnapshot.init))
        XCTAssertEqual(restored, state, "Polling after relaunch must not overwrite corrections or resurrect candidates")
        XCTAssertEqual(page.loadExtractedQuotes().first?.text, "Original source passage")
        try store.persist(nil)
        XCTAssertEqual(page.extractedQuotesData, original, "Clearing restores the exact original extraction bytes")
        XCTAssertEqual(page.imagePath, "captures/test/source.jpg")
    }

    func testPartialCommitPrunesCheckpointAtomicallyAndRetryDoesNotDuplicate() throws {
        enum Failure: Error { case write }
        let (session, page, book) = try fixture()
        let a = EditableQuote(pageId: page.id, text: "First approved passage", markingType: "underline")
        let b = EditableQuote(pageId: page.id, text: "Second approved passage", markingType: "underline")
        let excluded = EditableQuote(pageId: page.id, text: "Excluded input", markingType: "underline")
        var state = ExtractionReviewQuoteState(editingQuotes: [a, b, excluded], isLoading: false)
        state.setSelected(false, id: excluded.id)
        try ExtractionReviewCheckpointStore(session: session, modelContext: modelContext).persist(state)
        var writes = 0
        let store = ExtractionReviewCheckpointStore(session: session, modelContext: modelContext, persistChanges: {
            writes += 1
            if writes == 2 { throw Failure.write }
            try self.modelContext.save()
        })
        let result = store.save(candidates: [a, b], state: &state, to: book, markingDefinition: { _ in nil })
        XCTAssertEqual(result.savedQuotes.count, 1)
        XCTAssertEqual(result.failures.map(\.index), [1])
        XCTAssertEqual(state.editingQuotes.map(\.id), [b.id, excluded.id])
        try modelContext.save() // Must not commit a ghost insert from the failed operation.

        let fresh = ModelContext(modelContainer)
        let reloaded = try XCTUnwrap(fresh.fetch(FetchDescriptor<CaptureSession>()).first)
        let freshStore = ExtractionReviewCheckpointStore(session: reloaded, modelContext: fresh)
        var restored = try XCTUnwrap(freshStore.restore())
        XCTAssertEqual(restored, state)
        XCTAssertEqual(try fresh.fetchCount(FetchDescriptor<Quote>()), 1)
        let retry = freshStore.save(candidates: restored.selectedQuotes, state: &restored,
                                    to: try XCTUnwrap(reloaded.book), markingDefinition: { _ in nil })
        XCTAssertTrue(retry.isFullSuccess)
        XCTAssertEqual(try fresh.fetchCount(FetchDescriptor<Quote>()), 2)
        XCTAssertEqual(restored.editingQuotes.map(\.id), [excluded.id])
        XCTAssertTrue(restored.selectedQuotes.isEmpty)
    }

    func testManualFailureResolutionRollsBackOnWriteFailureAndDoesNotReimportSource() throws {
        enum Failure: Error { case write }
        let (session, page, _) = try fixture()
        page.failProcessing(error: "Offline")
        session.resumeReviewProcessing()
        let manual = EditableQuote(pageId: page.id, text: "Manually copied", markingType: "underline", isManual: true)
        var state = ExtractionReviewQuoteState(editingQuotes: [manual], isLoading: false)
        let store = ExtractionReviewCheckpointStore(session: session, modelContext: modelContext)
        try store.persist(state)
        let originalPayload = page.extractedQuotesData
        let failing = ExtractionReviewCheckpointStore(session: session, modelContext: modelContext,
                                                       persistChanges: { throw Failure.write })
        XCTAssertThrowsError(try failing.finishManualReview(of: page, state: &state))
        XCTAssertEqual(page.status, .failed)
        XCTAssertEqual(page.errorMessage, "Offline")
        XCTAssertEqual(session.failedPages, 1)
        XCTAssertEqual(session.status, .partialFailure)
        XCTAssertEqual(page.extractedQuotesData, originalPayload)
        try modelContext.save()
        try store.finishManualReview(of: page, state: &state)
        XCTAssertEqual(session.failedPages, 0)
        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(page.imagePath, "captures/test/source.jpg")
        XCTAssertEqual(page.loadExtractedQuotes().first?.text, "Original source passage")
        let fresh = ModelContext(modelContainer)
        let reloaded = try XCTUnwrap(fresh.fetch(FetchDescriptor<CaptureSession>()).first)
        var recovered = try XCTUnwrap(ExtractionReviewCheckpointStore(session: reloaded, modelContext: fresh).restore())
        recovered.loadCompletedQuotes(from: reloaded.captures.map(ExtractionReviewPageQuoteSnapshot.init))
        XCTAssertEqual(recovered.editingQuotes.map(\.id), [manual.id])
        XCTAssertTrue(recovered.editingQuotes[0].isManual)
        XCTAssertEqual(reloaded.failedPages, 0)
    }

    func testRepeatedApprovedCandidateCannotCreateASecondQuote() throws {
        let (session, page, book) = try fixture()
        let candidate = EditableQuote(pageId: page.id, text: "Commit once", markingType: "underline")
        var state = ExtractionReviewQuoteState(editingQuotes: [candidate], isLoading: false)
        let store = ExtractionReviewCheckpointStore(session: session, modelContext: modelContext)
        let result = store.save(candidates: [candidate, candidate], state: &state, to: book, markingDefinition: { _ in nil })
        XCTAssertEqual(result.savedQuotes.count, 1)
        XCTAssertEqual(result.failures.map(\.index), [1])
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<Quote>()), 1)
        XCTAssertTrue(state.editingQuotes.isEmpty)
        XCTAssertEqual(try store.restore(), state)
    }

    func testCorruptCheckpointIsRefusedWithoutOverwritingItsBytes() throws {
        let (session, page, _) = try fixture()
        try page.storeReviewCheckpointData(Data("not a checkpoint".utf8))
        let original = page.extractedQuotesData
        XCTAssertTrue(session.hasReviewCheckpoint)
        XCTAssertThrowsError(try ExtractionReviewCheckpointStore(session: session, modelContext: modelContext).restore())
        XCTAssertEqual(page.extractedQuotesData, original)
        XCTAssertEqual(page.loadExtractedQuotes().first?.text, "Original source passage")
    }

    func testFailedRetryAndInterruptedProcessingPreserveCheckpoint() throws {
        let (session, page, _) = try fixture()
        let state = ExtractionReviewQuoteState(editingQuotes: [
            EditableQuote(pageId: page.id, text: "Keep manual correction", markingType: "underline", isManual: true)
        ], isLoading: false)
        let store = ExtractionReviewCheckpointStore(session: session, modelContext: modelContext)
        try store.persist(state)
        page.failProcessing(error: "Offline")
        session.retryFailedCaptures()
        XCTAssertEqual(try store.restore(), state)
        page.beginProcessing()
        session.resumeReviewProcessing()
        XCTAssertEqual(page.status, .pending)
        XCTAssertEqual(session.status, .readyToProcess)
        XCTAssertEqual(try store.restore(), state)
    }
}
