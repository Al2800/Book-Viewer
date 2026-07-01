import XCTest

@testable import BookQuotes

@MainActor
final class CaptureQueueNetworkObserverTests: XCTestCase {
    func testStartsProcessingWhenPollSeesRestoredConnectionAndAutoProcessingIsEnabled() async {
        let networkMonitor = MutableCaptureQueueNetworkMonitor(isConnected: false)
        let poller = ScriptedCaptureQueueNetworkPoller {
            networkMonitor.isConnected = true
            return true
        }
        var startProcessingCount = 0

        let observer = CaptureQueueNetworkObserver(
            networkMonitor: networkMonitor,
            poller: poller
        )

        await observer.run(
            shouldAutoProcess: { true },
            startProcessing: { startProcessingCount += 1 }
        )

        XCTAssertEqual(networkMonitor.startMonitoringCallCount, 1)
        XCTAssertEqual(poller.pollCount, 2)
        XCTAssertEqual(startProcessingCount, 1)
    }
}

@MainActor
private final class MutableCaptureQueueNetworkMonitor: CaptureQueueNetworkMonitoring {
    private(set) var startMonitoringCallCount = 0
    var isConnected: Bool

    init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    func startMonitoring() {
        startMonitoringCallCount += 1
    }
}

@MainActor
private final class ScriptedCaptureQueueNetworkPoller: CaptureQueueNetworkPolling {
    private let firstPoll: () -> Bool
    private var didRunFirstPoll = false
    private(set) var pollCount = 0

    init(firstPoll: @escaping () -> Bool) {
        self.firstPoll = firstPoll
    }

    func waitForNextPoll() async -> Bool {
        pollCount += 1

        guard !didRunFirstPoll else { return false }
        didRunFirstPoll = true
        return firstPoll()
    }
}
