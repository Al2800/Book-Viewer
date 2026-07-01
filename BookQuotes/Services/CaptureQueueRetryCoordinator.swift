import Foundation

typealias CaptureQueueRetrySleep = @Sendable (TimeInterval) async -> Void

struct CaptureQueueRetryCoordinator {
    private let retryPolicy: CaptureQueueRetryPolicy
    private let sleep: CaptureQueueRetrySleep
    private var scheduler = CaptureQueueRetryScheduler()

    init(
        retryPolicy: CaptureQueueRetryPolicy = .standard,
        sleep: @escaping CaptureQueueRetrySleep = CaptureQueueRetryCoordinator.standardSleep
    ) {
        self.retryPolicy = retryPolicy
        self.sleep = sleep
    }

    var pendingRetryCount: Int {
        scheduler.pendingRetryCount
    }

    mutating func scheduleRetry(
        itemId: UUID,
        retryCount: Int,
        shouldRetry: @escaping @Sendable () async -> Bool,
        retry: @escaping @Sendable () async -> Void
    ) {
        let delay = retryPolicy.delay(for: retryCount)
        let sleep = sleep
        let task = Task {
            await sleep(delay)

            guard !Task.isCancelled else { return }
            guard await shouldRetry() else { return }

            await retry()
        }

        scheduler.schedule(task, for: itemId)
    }

    mutating func cancelRetry(for itemId: UUID) {
        scheduler.cancelRetry(for: itemId)
    }

    mutating func cancelAll() {
        scheduler.cancelAll()
    }

    private static func standardSleep(_ delay: TimeInterval) async {
        try? await Task.sleep(for: .seconds(delay))
    }
}
