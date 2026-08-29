import XCTest

@testable import BookQuotes

final class CaptureFlowStateTests: XCTestCase {

    func testCaptureModeOptionsPreserveOrderAndAccessibilityContracts() {
        let options = CaptureModeOption.all

        XCTAssertEqual(options.map(\.kind), [.cover, .quote, .batch])
        XCTAssertEqual(options.map(\.title), ["Add New Book", "Capture Quotes", "Batch Mode"])
        XCTAssertEqual(
            options.map(\.accessibilityId),
            [
                AccessibilityIdentifiers.Capture.modeSelectCover,
                AccessibilityIdentifiers.Capture.modeSelectQuote,
                AccessibilityIdentifiers.Capture.modeSelectBatch
            ]
        )
    }

    func testSelectionEventsMoveToExpectedModes() {
        var state = CaptureFlowState()

        XCTAssertEqual(state.mode, .selection)

        let coverCommand = state.handle(.selectCoverCapture)
        XCTAssertEqual(state.mode, .coverCapture)
        XCTAssertFalse(coverCommand.clearsSelectedBook)

        state = CaptureFlowState()
        let quoteCommand = state.handle(.selectQuoteCapture)
        XCTAssertEqual(state.mode, .bookSelection)
        XCTAssertFalse(quoteCommand.clearsSelectedBook)

        state = CaptureFlowState()
        let batchCommand = state.handle(.selectBatchCapture)
        XCTAssertEqual(state.mode, .bookSelectionForBatch)
        XCTAssertFalse(batchCommand.clearsSelectedBook)
    }

    func testSelectingABookRefreshesTheRelevantCaptureFlowIdentity() {
        var state = CaptureFlowState()
        let originalQuoteFlowID = state.quoteCaptureFlowID
        let originalBatchFlowID = state.batchCaptureFlowID

        let quoteCommand = state.handle(.selectBookForQuoteCapture)

        XCTAssertEqual(state.mode, .quoteCapture)
        XCTAssertNotEqual(state.quoteCaptureFlowID, originalQuoteFlowID)
        XCTAssertEqual(state.batchCaptureFlowID, originalBatchFlowID)
        XCTAssertFalse(quoteCommand.clearsSelectedBook)

        state = CaptureFlowState()
        let nextQuoteFlowID = state.quoteCaptureFlowID
        let nextBatchFlowID = state.batchCaptureFlowID

        let batchCommand = state.handle(.selectBookForBatchCapture)

        XCTAssertEqual(state.mode, .batchCapture)
        XCTAssertEqual(state.quoteCaptureFlowID, nextQuoteFlowID)
        XCTAssertNotEqual(state.batchCaptureFlowID, nextBatchFlowID)
        XCTAssertFalse(batchCommand.clearsSelectedBook)
    }

    func testResumeBatchCaptureEntersBatchModeWithFreshIdentity() {
        var state = CaptureFlowState()
        let originalID = state.batchCaptureFlowID

        let command = state.handle(.resumeBatchCapture)

        XCTAssertEqual(state.mode, .batchCapture)
        XCTAssertNotEqual(state.batchCaptureFlowID, originalID)
        XCTAssertEqual(command, .none)
    }

    func testCompletionAndCancellationPreserveCurrentSelectedBookClearingBehavior() {
        var state = CaptureFlowState()

        _ = state.handle(.completeCoverCapture)
        XCTAssertEqual(state.mode, .selection)
        XCTAssertFalse(state.handle(.cancelCoverCapture).clearsSelectedBook)

        state = CaptureFlowState(mode: .quoteCapture)
        let quoteCompleteCommand = state.handle(.completeQuoteCapture)
        XCTAssertEqual(state.mode, .selection)
        XCTAssertTrue(quoteCompleteCommand.clearsSelectedBook)

        state = CaptureFlowState(mode: .quoteCapture)
        let quoteCancelCommand = state.handle(.cancelQuoteCapture)
        XCTAssertEqual(state.mode, .selection)
        XCTAssertTrue(quoteCancelCommand.clearsSelectedBook)

        state = CaptureFlowState(mode: .batchCapture)
        let batchCompleteCommand = state.handle(.completeBatchCapture)
        XCTAssertEqual(state.mode, .selection)
        XCTAssertTrue(batchCompleteCommand.clearsSelectedBook)

        state = CaptureFlowState(mode: .batchCapture)
        let batchCancelCommand = state.handle(.cancelBatchCapture)
        XCTAssertEqual(state.mode, .selection)
        XCTAssertTrue(batchCancelCommand.clearsSelectedBook)
    }

    func testBookSelectionCancellationAndAddNewBookTransitions() {
        var quoteSelectionState = CaptureFlowState(mode: .bookSelection)
        let addFromQuoteCommand = quoteSelectionState.handle(.addNewBook)
        XCTAssertEqual(quoteSelectionState.mode, .coverCapture)
        XCTAssertFalse(addFromQuoteCommand.clearsSelectedBook)

        var batchSelectionState = CaptureFlowState(mode: .bookSelectionForBatch)
        let addFromBatchCommand = batchSelectionState.handle(.addNewBook)
        XCTAssertEqual(batchSelectionState.mode, .coverCapture)
        XCTAssertFalse(addFromBatchCommand.clearsSelectedBook)

        var cancelState = CaptureFlowState(mode: .bookSelection)
        let cancelCommand = cancelState.handle(.cancelBookSelection)
        XCTAssertEqual(cancelState.mode, .selection)
        XCTAssertFalse(cancelCommand.clearsSelectedBook)
    }

    func testSwitchActiveBookAndToggleBatchModeTransitions() {
        var state = CaptureFlowState(mode: .quoteCapture)
        let originalQuoteID = state.quoteCaptureFlowID

        state.handle(.switchActiveBook)
        XCTAssertEqual(state.mode, .quoteCapture)
        XCTAssertNotEqual(state.quoteCaptureFlowID, originalQuoteID)

        state.handle(.toggleBatchMode)
        XCTAssertEqual(state.mode, .batchCapture)

        state.handle(.toggleBatchMode)
        XCTAssertEqual(state.mode, .quoteCapture)
    }
}
