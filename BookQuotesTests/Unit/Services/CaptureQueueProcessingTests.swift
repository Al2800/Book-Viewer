import XCTest

@testable import BookQuotes

final class CaptureQueueProcessingTests: XCTestCase {
    func testFailedRetryableOutcomeRequestsRetryScheduling() {
        let itemId = UUID()
        let outcome = CaptureQueueProcessingOutcome.failed(
            itemId: itemId,
            retryCount: 2,
            canRetry: true
        )

        XCTAssertEqual(
            outcome.retryRequest,
            CaptureQueueRetryRequest(itemId: itemId, retryCount: 2)
        )
    }

    func testFailedNonRetryableOutcomeDoesNotRequestRetryScheduling() {
        let outcome = CaptureQueueProcessingOutcome.failed(
            itemId: UUID(),
            retryCount: 3,
            canRetry: false
        )

        XCTAssertNil(outcome.retryRequest)
    }

    func testTerminalOutcomesDoNotRequestRetryScheduling() {
        XCTAssertNil(CaptureQueueProcessingOutcome.completed.retryRequest)
        XCTAssertNil(CaptureQueueProcessingOutcome.missing.retryRequest)
    }
}
