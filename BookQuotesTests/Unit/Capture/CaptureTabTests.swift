import XCTest
import SwiftUI
@testable import BookQuotes

@MainActor
final class CaptureTabTests: XCTestCase {
    func testCaptureTabInitializesCleanly() {
        var viewedBook: Book?

        var didExit = false
        let tab = CaptureTab(
            onViewPassages: { book in viewedBook = book },
            onExit: { didExit = true }
        )
        XCTAssertNotNil(tab)
        XCTAssertNil(viewedBook)
        XCTAssertFalse(didExit)
    }

    func testCaptureStateEqualityUsesPreviewingProcessingAndCompletedOnly() {
        XCTAssertEqual(QuoteCaptureView.CaptureState.previewing, .previewing)
        XCTAssertEqual(QuoteCaptureView.CaptureState.processing, .processing)
        XCTAssertNotEqual(QuoteCaptureView.CaptureState.previewing, .processing)
    }

    func testQuietCaptureRetakeThreshold() {
        XCTAssertTrue(
            QuoteCaptureView.shouldSuggestRetake(isAcceptable: false, overallScore: 0.39)
        )
        XCTAssertFalse(
            QuoteCaptureView.shouldSuggestRetake(isAcceptable: false, overallScore: 0.41)
        )
        XCTAssertFalse(
            QuoteCaptureView.shouldSuggestRetake(isAcceptable: true, overallScore: 0.2)
        )
    }

    func testCaptureFlowStateDirectsToActiveReadingByDefault() {
        let state = CaptureFlowState(mode: .quoteCapture)
        XCTAssertEqual(state.mode, .quoteCapture)
    }

    func testCaptureFlowTransitionsToBatchAndBack() {
        var state = CaptureFlowState(mode: .quoteCapture)
        state.handle(.toggleBatchMode)
        XCTAssertEqual(state.mode, .batchCapture)

        state.handle(.toggleBatchMode)
        XCTAssertEqual(state.mode, .quoteCapture)
    }

    func testCaptureFlowSwitchesActiveBookWithFreshFlowID() {
        var state = CaptureFlowState(mode: .quoteCapture)
        let initialID = state.quoteCaptureFlowID

        state.handle(.switchActiveBook)
        XCTAssertEqual(state.mode, .quoteCapture)
        XCTAssertNotEqual(state.quoteCaptureFlowID, initialID)
    }

    func testCaptureFlowEntersCoverCaptureForNewBook() {
        var state = CaptureFlowState(mode: .quoteCapture)
        state.handle(.addNewBook)
        XCTAssertEqual(state.mode, .coverCapture)

        state.handle(.completeCoverCapture)
        XCTAssertEqual(state.mode, .selection)
    }
}
