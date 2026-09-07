import XCTest

@testable import BookQuotes

final class ExtractionReviewQuoteStateTests: XCTestCase {

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
