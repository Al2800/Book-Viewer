import XCTest

@testable import BookQuotes

@MainActor
final class CaptureQueueSupportTests: SwiftDataTestCase {
    func testInitialStatsAreAllZero() {
        let stats = QueueStats()

        XCTAssertEqual(stats.pendingCount, 0)
        XCTAssertEqual(stats.processingCount, 0)
        XCTAssertEqual(stats.failedCount, 0)
        XCTAssertEqual(stats.completedCount, 0)
        XCTAssertFalse(stats.isProcessing)
    }

    func testStatsTotalActiveExcludesCompleted() {
        let stats = QueueStats(
            pendingCount: 3,
            processingCount: 1,
            failedCount: 2,
            completedCount: 10,
            isProcessing: true
        )

        XCTAssertEqual(stats.totalActive, 6)
        XCTAssertTrue(stats.hasActiveItems)
    }

    func testStatsHasActiveItemsIsFalseWhenEmpty() {
        XCTAssertFalse(QueueStats().hasActiveItems)
    }

    func testStatsStatusDescriptionShowsProcessingState() {
        let stats = QueueStats(
            pendingCount: 2,
            processingCount: 1,
            failedCount: 0,
            completedCount: 5,
            isProcessing: true
        )

        XCTAssertTrue(stats.statusDescription.contains("Processing"))
    }

    func testStatsStatusDescriptionShowsWaitingState() {
        let stats = QueueStats(
            pendingCount: 3,
            processingCount: 0,
            failedCount: 0,
            completedCount: 0,
            isProcessing: false
        )

        XCTAssertTrue(stats.statusDescription.contains("waiting"))
    }

    func testStatsStatusDescriptionShowsFailedState() {
        let stats = QueueStats(
            pendingCount: 0,
            processingCount: 0,
            failedCount: 2,
            completedCount: 5,
            isProcessing: false
        )

        XCTAssertTrue(stats.statusDescription.contains("failed"))
    }

    func testStatsStatusDescriptionShowsEmptyState() {
        XCTAssertTrue(QueueStats().statusDescription.contains("empty"))
    }

    func testRetryPolicy_ClampsRetryCountToConfiguredDelays() {
        let policy = CaptureQueueRetryPolicy(delays: [5, 30, 120])

        XCTAssertEqual(policy.delay(for: 0), 5)
        XCTAssertEqual(policy.delay(for: 1), 5)
        XCTAssertEqual(policy.delay(for: 2), 30)
        XCTAssertEqual(policy.delay(for: 3), 120)
        XCTAssertEqual(policy.delay(for: 99), 120)
    }

    func testProcessingStartPolicy_AutomaticStartsRequireConnectionAndAutoProcessing() {
        XCTAssertTrue(
            CaptureQueueProcessingStartPolicy.shouldStartProcessing(
                reason: .managerStart,
                isConnected: true,
                isAutoProcessEnabled: true
            )
        )
        XCTAssertTrue(
            CaptureQueueProcessingStartPolicy.shouldStartProcessing(
                reason: .itemQueued,
                isConnected: true,
                isAutoProcessEnabled: true
            )
        )

        XCTAssertFalse(
            CaptureQueueProcessingStartPolicy.shouldStartProcessing(
                reason: .managerStart,
                isConnected: true,
                isAutoProcessEnabled: false
            )
        )
        XCTAssertFalse(
            CaptureQueueProcessingStartPolicy.shouldStartProcessing(
                reason: .itemQueued,
                isConnected: false,
                isAutoProcessEnabled: true
            )
        )
    }

    func testProcessingStartPolicy_ManualStartsRequireConnectionOnly() {
        for reason in CaptureQueueProcessingStartReason.manualReasons {
            XCTAssertTrue(
                CaptureQueueProcessingStartPolicy.shouldStartProcessing(
                    reason: reason,
                    isConnected: true,
                    isAutoProcessEnabled: false
                ),
                "\(reason) should start while connected even when auto-processing is disabled"
            )
            XCTAssertFalse(
                CaptureQueueProcessingStartPolicy.shouldStartProcessing(
                    reason: reason,
                    isConnected: false,
                    isAutoProcessEnabled: true
                ),
                "\(reason) should not start while offline"
            )
        }
    }

    func testStatsBuilder_CountsQueueStatusesAndExcludesCancelledFromActiveTotal() throws {
        let book = TestFixtures.atomicHabits
        try insertBook(book)

        let pending = CaptureQueueItem(book: book, imagePath: "pending.jpg")
        pending.status = .pending

        let processing = CaptureQueueItem(book: book, imagePath: "processing.jpg")
        processing.status = .processing

        let failed = CaptureQueueItem(book: book, imagePath: "failed.jpg")
        failed.status = .failed

        let completed = CaptureQueueItem(book: book, imagePath: "completed.jpg")
        completed.status = .completed

        let cancelled = CaptureQueueItem(book: book, imagePath: "cancelled.jpg")
        cancelled.status = .cancelled

        let stats = CaptureQueueStatsBuilder.stats(
            from: [pending, processing, failed, completed, cancelled],
            isProcessing: true
        )

        XCTAssertEqual(stats.pendingCount, 1)
        XCTAssertEqual(stats.processingCount, 1)
        XCTAssertEqual(stats.failedCount, 1)
        XCTAssertEqual(stats.completedCount, 1)
        XCTAssertEqual(stats.totalActive, 3)
        XCTAssertTrue(stats.isProcessing)
    }

    func testQueueErrorDescriptionsArePresent() {
        let errors: [QueueError] = [
            .imageStorageFailed,
            .imageLoadFailed,
            .bookNotFound,
            .itemNotFound,
            .processingFailed(NSError(domain: "test", code: 1))
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
        }
    }

    func testQueueErrorProcessingFailedIncludesUnderlyingError() {
        let underlying = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Test error message"]
        )
        let error = QueueError.processingFailed(underlying)

        XCTAssertTrue(error.errorDescription?.contains("Test error message") ?? false)
    }
}
