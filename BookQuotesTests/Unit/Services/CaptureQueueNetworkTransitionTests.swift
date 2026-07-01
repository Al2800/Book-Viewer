import XCTest

@testable import BookQuotes

final class CaptureQueueNetworkTransitionTests: XCTestCase {
    func testStartsProcessingOnlyWhenConnectionIsRestoredAndAutoProcessingIsEnabled() {
        XCTAssertTrue(
            CaptureQueueNetworkTransition.shouldStartProcessing(
                wasConnected: false,
                isConnected: true,
                isAutoProcessEnabled: true
            )
        )

        XCTAssertFalse(
            CaptureQueueNetworkTransition.shouldStartProcessing(
                wasConnected: false,
                isConnected: true,
                isAutoProcessEnabled: false
            )
        )
        XCTAssertFalse(
            CaptureQueueNetworkTransition.shouldStartProcessing(
                wasConnected: true,
                isConnected: true,
                isAutoProcessEnabled: true
            )
        )
        XCTAssertFalse(
            CaptureQueueNetworkTransition.shouldStartProcessing(
                wasConnected: true,
                isConnected: false,
                isAutoProcessEnabled: true
            )
        )
    }
}
