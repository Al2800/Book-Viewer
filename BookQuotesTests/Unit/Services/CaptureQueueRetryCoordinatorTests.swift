import XCTest

@testable import BookQuotes

final class CaptureQueueRetryCoordinatorTests: XCTestCase {
    func testScheduleRetryRunsRetryAfterConfiguredDelayWhenStillRetryable() async throws {
        let sleepRecorder = RetrySleepRecorder()
        let retryRecorder = RetryActionRecorder()
        var coordinator = CaptureQueueRetryCoordinator(
            retryPolicy: CaptureQueueRetryPolicy(delays: [12]),
            sleep: { delay in await sleepRecorder.sleep(delay: delay) }
        )

        coordinator.scheduleRetry(
            itemId: UUID(),
            retryCount: 1,
            shouldRetry: { true },
            retry: { await retryRecorder.record() }
        )

        try await retryRecorder.waitForRetryCount(1)

        let delays = await sleepRecorder.recordedDelays()
        let retryCount = await retryRecorder.recordedRetryCount()
        XCTAssertEqual(delays, [12])
        XCTAssertEqual(retryCount, 1)
    }

    func testCancelRetryPreventsScheduledRetryFromRunning() async throws {
        let itemId = UUID()
        let sleepGate = RetrySleepGate()
        let retryRecorder = RetryActionRecorder()
        var coordinator = CaptureQueueRetryCoordinator(
            retryPolicy: CaptureQueueRetryPolicy(delays: [12]),
            sleep: { delay in await sleepGate.sleep(delay: delay) }
        )

        coordinator.scheduleRetry(
            itemId: itemId,
            retryCount: 1,
            shouldRetry: { true },
            retry: { await retryRecorder.record() }
        )
        try await sleepGate.waitUntilSleeping()
        coordinator.cancelRetry(for: itemId)

        await sleepGate.release()
        try await retryRecorder.waitForNoRetry()

        let retryCount = await retryRecorder.recordedRetryCount()
        XCTAssertEqual(retryCount, 0)
    }
}

private actor RetrySleepRecorder {
    private(set) var delays: [TimeInterval] = []

    func sleep(delay: TimeInterval) async {
        delays.append(delay)
    }

    func recordedDelays() -> [TimeInterval] {
        delays
    }
}

private actor RetrySleepGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isSleeping = false

    func sleep(delay: TimeInterval) async {
        isSleeping = true
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitUntilSleeping(timeout: TimeInterval = 1.0) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while !isSleeping && Date() < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        XCTAssertTrue(isSleeping)
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}

private actor RetryActionRecorder {
    private(set) var retryCount = 0

    func record() {
        retryCount += 1
    }

    func recordedRetryCount() -> Int {
        retryCount
    }

    func waitForRetryCount(
        _ expectedCount: Int,
        timeout: TimeInterval = 1.0
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while retryCount < expectedCount && Date() < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        XCTAssertEqual(retryCount, expectedCount)
    }

    func waitForNoRetry() async throws {
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(retryCount, 0)
    }
}
