import XCTest
import SwiftUI
@testable import BookQuotes

@MainActor
final class CaptureTabTests: XCTestCase {
    func testCaptureTabInitializesCleanly() {
        var bookCreated: Book?
        var quotesSaved: Book?

        let tab = CaptureTab(
            onBookCreated: { book in bookCreated = book },
            onQuotesSaved: { book in quotesSaved = book }
        )
        XCTAssertNotNil(tab)
        XCTAssertNil(bookCreated)
        XCTAssertNil(quotesSaved)
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
