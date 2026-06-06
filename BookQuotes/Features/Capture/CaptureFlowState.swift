import Foundation

struct CaptureFlowState: Equatable {
    enum Mode: Equatable {
        case selection
        case bookSelection
        case bookSelectionForBatch
        case coverCapture
        case quoteCapture
        case batchCapture
    }

    enum Event: Equatable {
        case selectCoverCapture
        case selectQuoteCapture
        case selectBatchCapture
        case selectBookForQuoteCapture
        case selectBookForBatchCapture
        case addNewBook
        case cancelBookSelection
        case completeCoverCapture
        case cancelCoverCapture
        case completeQuoteCapture
        case cancelQuoteCapture
        case completeBatchCapture
        case cancelBatchCapture
    }

    struct Command: Equatable {
        var clearsSelectedBook: Bool

        static let none = Command(clearsSelectedBook: false)
        static let clearSelectedBook = Command(clearsSelectedBook: true)
    }

    var mode: Mode
    var quoteCaptureFlowID: UUID
    var batchCaptureFlowID: UUID

    init(
        mode: Mode = .selection,
        quoteCaptureFlowID: UUID = UUID(),
        batchCaptureFlowID: UUID = UUID()
    ) {
        self.mode = mode
        self.quoteCaptureFlowID = quoteCaptureFlowID
        self.batchCaptureFlowID = batchCaptureFlowID
    }

    @discardableResult
    mutating func handle(_ event: Event) -> Command {
        switch event {
        case .selectCoverCapture:
            mode = .coverCapture
            return .none

        case .selectQuoteCapture:
            mode = .bookSelection
            return .none

        case .selectBatchCapture:
            mode = .bookSelectionForBatch
            return .none

        case .selectBookForQuoteCapture:
            quoteCaptureFlowID = UUID()
            mode = .quoteCapture
            return .none

        case .selectBookForBatchCapture:
            batchCaptureFlowID = UUID()
            mode = .batchCapture
            return .none

        case .addNewBook:
            mode = .coverCapture
            return .none

        case .cancelBookSelection, .completeCoverCapture, .cancelCoverCapture:
            mode = .selection
            return .none

        case .completeQuoteCapture, .cancelQuoteCapture:
            mode = .selection
            return .clearSelectedBook

        case .completeBatchCapture, .cancelBatchCapture:
            mode = .selection
            return .clearSelectedBook
        }
    }
}
