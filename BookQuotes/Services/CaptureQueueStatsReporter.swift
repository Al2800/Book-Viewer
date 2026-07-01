import Combine

final class CaptureQueueStatsReporter: @unchecked Sendable {
    private let subject = CurrentValueSubject<QueueStats, Never>(QueueStats())

    var stats: QueueStats {
        subject.value
    }

    var publisher: AnyPublisher<QueueStats, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ stats: QueueStats) {
        subject.send(stats)
    }
}
