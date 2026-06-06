import XCTest

@testable import BookQuotes

final class BatchCaptureLifecycleStateTests: XCTestCase {

    func testStatusTextDescribesEmptySingularAndPluralPageCounts() {
        let state = BatchCaptureLifecycleState()

        XCTAssertEqual(state.statusText(pageCount: 0), "Capture pages for one review session")
        XCTAssertEqual(state.statusText(pageCount: 1), "1 page ready to process")
        XCTAssertEqual(state.statusText(pageCount: 3), "3 pages ready to process")
    }

    func testFinishAndCancelDecisionsPreserveCurrentConfirmationBehaviour() {
        var state = BatchCaptureLifecycleState()

        XCTAssertFalse(state.canFinish(pageCount: 0))
        XCTAssertEqual(state.requestFinish(pageCount: 0), .none)
        XCTAssertFalse(state.showsFinishConfirmation)

        XCTAssertTrue(state.canFinish(pageCount: 2))
        XCTAssertEqual(state.requestFinish(pageCount: 2), .showFinishConfirmation)
        XCTAssertTrue(state.showsFinishConfirmation)

        state.showsFinishConfirmation = false
        XCTAssertEqual(state.requestCancel(pageCount: 0), .cancel)
        XCTAssertFalse(state.showsFinishConfirmation)

        XCTAssertEqual(state.requestCancel(pageCount: 1), .showFinishConfirmation)
        XCTAssertTrue(state.showsFinishConfirmation)
    }

    func testOfflineQueueCompletionShowsConfirmationOnlyWhenPagesWereQueued() {
        var state = BatchCaptureLifecycleState()

        XCTAssertEqual(state.completeOfflineQueue(queuedCount: 0), .complete)
        XCTAssertEqual(state.queuedCount, 0)
        XCTAssertFalse(state.showsOfflineConfirmation)

        XCTAssertEqual(state.completeOfflineQueue(queuedCount: 4), .showOfflineConfirmation)
        XCTAssertEqual(state.queuedCount, 4)
        XCTAssertTrue(state.showsOfflineConfirmation)
    }
}
