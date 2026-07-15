import Combine
import Foundation

final class CaptureQueueStatsReporter: @unchecked Sendable {
    private let stateLock = NSLock()
    private let subject = CurrentValueSubject<QueueStats, Never>(QueueStats())
    private var currentStats = QueueStats()

    var stats: QueueStats {
        stateLock.lock()
        defer { stateLock.unlock() }
        return currentStats
    }

    var publisher: AnyPublisher<QueueStats, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ stats: QueueStats) {
        stateLock.lock()
        currentStats = stats
        stateLock.unlock()

        subject.send(stats)
    }
}
