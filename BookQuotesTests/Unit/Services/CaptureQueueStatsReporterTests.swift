import Combine
import XCTest

@testable import BookQuotes

final class CaptureQueueStatsReporterTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testStartsWithEmptyQueueStats() {
        let reporter = CaptureQueueStatsReporter()

        XCTAssertEqual(reporter.stats, QueueStats())
    }

    func testPublishUpdatesCurrentStats() {
        let reporter = CaptureQueueStatsReporter()
        let stats = QueueStats(
            pendingCount: 2,
            processingCount: 1,
            failedCount: 0,
            completedCount: 3,
            isProcessing: true
        )

        reporter.publish(stats)

        XCTAssertEqual(reporter.stats, stats)
    }

    func testPublisherEmitsPublishedStats() async {
        let reporter = CaptureQueueStatsReporter()
        let expectedStats = QueueStats(pendingCount: 1)
        let expectation = expectation(description: "Published stats emitted")
        var receivedStats: [QueueStats] = []

        reporter.publisher
            .dropFirst()
            .sink { stats in
                receivedStats.append(stats)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        reporter.publish(expectedStats)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStats, [expectedStats])
    }
}
