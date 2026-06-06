import Foundation

enum BatchCaptureLifecycleCommand: Equatable {
    case none
    case cancel
    case complete
    case showFinishConfirmation
    case showOfflineConfirmation
}

struct BatchCaptureLifecycleState {
    var isCapturing = false
    var showsFinishConfirmation = false
    var showsCaptureDetail = false
    var showsOfflineConfirmation = false
    var queuedCount = 0

    func canFinish(pageCount: Int) -> Bool {
        pageCount > 0
    }

    func statusText(pageCount: Int) -> String {
        if pageCount == 0 {
            return "Capture pages for one review session"
        }

        return "\(pageCount) page\(pageCount == 1 ? "" : "s") ready to process"
    }

    mutating func requestFinish(pageCount: Int) -> BatchCaptureLifecycleCommand {
        guard canFinish(pageCount: pageCount) else { return .none }

        showsFinishConfirmation = true
        return .showFinishConfirmation
    }

    mutating func requestCancel(pageCount: Int) -> BatchCaptureLifecycleCommand {
        guard pageCount > 0 else { return .cancel }

        showsFinishConfirmation = true
        return .showFinishConfirmation
    }

    mutating func completeOfflineQueue(queuedCount: Int) -> BatchCaptureLifecycleCommand {
        guard queuedCount > 0 else { return .complete }

        self.queuedCount = queuedCount
        showsOfflineConfirmation = true
        return .showOfflineConfirmation
    }
}
