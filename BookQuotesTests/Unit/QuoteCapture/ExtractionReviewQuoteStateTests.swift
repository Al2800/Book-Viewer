import XCTest

@testable import BookQuotes

final class ExtractionReviewQuoteStateTests: XCTestCase {

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
                        confidence: 0.91
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

        let secondQuote = state.quotes(for: secondPageId).first
        XCTAssertEqual(secondQuote?.pageNumber, 12)
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
