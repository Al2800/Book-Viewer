import XCTest

@testable import BookQuotes

final class CaptureQueueRetrySchedulerTests: XCTestCase {
    func testScheduleReplacesExistingRetryForSameItem() {
        var scheduler = CaptureQueueRetryScheduler()
        let itemId = UUID()
        let firstTask = Task<Void, Never> {}
        let secondTask = Task<Void, Never> {}

        scheduler.schedule(firstTask, for: itemId)
        scheduler.schedule(secondTask, for: itemId)

        XCTAssertTrue(firstTask.isCancelled)
        XCTAssertFalse(secondTask.isCancelled)
        XCTAssertTrue(scheduler.hasPendingRetry(for: itemId))
        XCTAssertEqual(scheduler.pendingRetryCount, 1)
    }

    func testCancelPendingRetryCancelsAndRemovesTask() {
        var scheduler = CaptureQueueRetryScheduler()
        let itemId = UUID()
        let task = Task<Void, Never> {}

        scheduler.schedule(task, for: itemId)
        scheduler.cancelRetry(for: itemId)

        XCTAssertTrue(task.isCancelled)
        XCTAssertFalse(scheduler.hasPendingRetry(for: itemId))
        XCTAssertEqual(scheduler.pendingRetryCount, 0)
    }

    func testCancelAllPendingRetriesCancelsEveryTask() {
        var scheduler = CaptureQueueRetryScheduler()
        let firstTask = Task<Void, Never> {}
        let secondTask = Task<Void, Never> {}

        scheduler.schedule(firstTask, for: UUID())
        scheduler.schedule(secondTask, for: UUID())
        scheduler.cancelAll()

        XCTAssertTrue(firstTask.isCancelled)
        XCTAssertTrue(secondTask.isCancelled)
        XCTAssertEqual(scheduler.pendingRetryCount, 0)
    }
}
