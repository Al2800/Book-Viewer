import Foundation

@MainActor
protocol CaptureQueueNetworkPolling: AnyObject {
    func waitForNextPoll() async -> Bool
}

@MainActor
final class CaptureQueueNetworkPoller: CaptureQueueNetworkPolling {
    private let interval: Duration

    nonisolated init(interval: Duration = .seconds(1)) {
        self.interval = interval
    }

    func waitForNextPoll() async -> Bool {
        do {
            try await Task.sleep(for: interval)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}

@MainActor
struct CaptureQueueNetworkObserver {
    let networkMonitor: any CaptureQueueNetworkMonitoring
    let poller: any CaptureQueueNetworkPolling

    func run(
        shouldAutoProcess: () async -> Bool,
        startProcessing: () async -> Void
    ) async {
        networkMonitor.startMonitoring()

        var wasConnected = networkMonitor.isConnected

        while !Task.isCancelled {
            guard await poller.waitForNextPoll() else { break }

            let isNowConnected = networkMonitor.isConnected
            let shouldStartProcessing = CaptureQueueNetworkTransition.shouldStartProcessing(
                wasConnected: wasConnected,
                isConnected: isNowConnected,
                isAutoProcessEnabled: await shouldAutoProcess()
            )

            if shouldStartProcessing {
                await startProcessing()
            }

            wasConnected = isNowConnected
        }
    }
}
