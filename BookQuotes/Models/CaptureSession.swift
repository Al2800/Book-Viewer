import Foundation
import SwiftData

// MARK: - Capture Session Model

/// Represents a multi-page batch capture session.
/// Groups related page captures and tracks overall processing state.
@Model
final class CaptureSession {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Timing

    /// When the capture session started
    var dateStarted: Date

    /// When processing completed (nil if still in progress)
    var dateCompleted: Date?

    // MARK: - Status

    /// Current status of the session
    var status: SessionStatus

    // MARK: - Statistics

    /// Total number of pages captured
    var totalPages: Int

    /// Number of pages successfully processed
    var processedPages: Int

    /// Number of pages that failed processing
    var failedPages: Int

    // MARK: - Relationships

    /// The book these captures belong to
    var book: Book?

    /// Individual page captures in this session
    @Relationship(deleteRule: .cascade, inverse: \PageCapture.session)
    var captures: [PageCapture]

    // MARK: - Computed Properties

    /// Number of pages pending processing
    var pendingPages: Int {
        totalPages - processedPages - failedPages
    }

    /// Whether all pages have been processed
    var isComplete: Bool {
        pendingPages == 0 && status != .capturing
    }

    /// Progress as a value from 0.0 to 1.0
    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(processedPages + failedPages) / Double(totalPages)
    }

    /// Whether the session has any failures
    var hasFailures: Bool {
        failedPages > 0
    }

    /// Total quotes extracted across all captures
    var totalQuotesExtracted: Int {
        captures.reduce(0) { $0 + ($1.extractedQuoteCount) }
    }

    /// Duration of the capture session (if completed)
    var duration: TimeInterval? {
        guard let completed = dateCompleted else { return nil }
        return completed.timeIntervalSince(dateStarted)
    }

    // MARK: - Initialization

    init(book: Book? = nil) {
        self.id = UUID()
        self.dateStarted = Date()
        self.status = .capturing
        self.totalPages = 0
        self.processedPages = 0
        self.failedPages = 0
        self.book = book
        self.captures = []
    }

    // MARK: - Session Management

    /// Add a new page capture to the session
    func addCapture(_ capture: PageCapture) {
        // SwiftData inverse relationships may already have linked this capture to `captures`
        // if `capture.session` was set. Make this method idempotent and self-healing.
        if capture.session?.id != id {
            capture.session = self
        }

        if !captures.contains(where: { $0.id == capture.id }) {
            captures.append(capture)
        }

        // Normalize ordering and keep derived counts consistent.
        for (index, item) in captures.enumerated() {
            item.orderIndex = index
        }
        totalPages = captures.count
    }

    /// Mark session as ready for processing
    func finishCapturing() {
        guard status == .capturing else { return }
        status = totalPages > 0 ? .readyToProcess : .completed
    }

    /// Return a saved draft to capture mode so pages can be added or reviewed.
    func resumeCapturing() {
        guard status == .readyToProcess else { return }
        status = .capturing
        dateCompleted = nil
    }

    /// Begin processing the captured pages
    func beginProcessing() {
        guard status == .readyToProcess else { return }
        status = .processing
    }

    /// Record a successful page processing
    func recordSuccess() {
        processedPages += 1
        updateCompletionStatus()
    }

    /// Record a failed page processing
    func recordFailure() {
        failedPages += 1
        updateCompletionStatus()
    }

    /// Update completion status based on current counts
    private func updateCompletionStatus() {
        guard status == .processing else { return }

        if pendingPages == 0 {
            dateCompleted = Date()
            status = failedPages > 0 ? .partialFailure : .completed
        }
    }

    /// Cancel the session
    func cancel() {
        status = .cancelled
        dateCompleted = Date()
    }

    /// Remove full page images after reviewed quotes are safely persisted.
    @discardableResult
    func deleteImageFiles() -> Int {
        captures.reduce(into: 0) { removedCount, capture in
            if capture.deleteImageFile() {
                removedCount += 1
            }
        }
    }
}

// MARK: - Session Status

extension CaptureSession {
    /// Status of a capture session
    enum SessionStatus: String, Codable, CaseIterable {
        /// Actively capturing pages
        case capturing

        /// Done capturing, waiting to process
        case readyToProcess

        /// API calls in progress
        case processing

        /// All pages processed successfully
        case completed

        /// Some pages failed processing
        case partialFailure

        /// Session was cancelled
        case cancelled

        var displayName: String {
            switch self {
            case .capturing: return "Capturing"
            case .readyToProcess: return "Ready"
            case .processing: return "Processing"
            case .completed: return "Completed"
            case .partialFailure: return "Partial"
            case .cancelled: return "Cancelled"
            }
        }

        var icon: String {
            switch self {
            case .capturing: return "camera"
            case .readyToProcess: return "clock"
            case .processing: return "gearshape.2"
            case .completed: return "checkmark.circle"
            case .partialFailure: return "exclamationmark.triangle"
            case .cancelled: return "xmark.circle"
            }
        }

        var isActive: Bool {
            switch self {
            case .capturing, .readyToProcess, .processing:
                return true
            case .completed, .partialFailure, .cancelled:
                return false
            }
        }
    }
}

// MARK: - Query Descriptors

extension CaptureSession {
    /// Active sessions (not completed or cancelled)
    static var active: FetchDescriptor<CaptureSession> {
        FetchDescriptor<CaptureSession>(
            sortBy: [SortDescriptor(\.dateStarted, order: .reverse)]
        )
    }

    /// Recent sessions (all statuses)
    static var recent: FetchDescriptor<CaptureSession> {
        FetchDescriptor<CaptureSession>(
            sortBy: [SortDescriptor(\.dateStarted, order: .reverse)]
        )
    }

    /// Sessions with failures
    static var withFailures: FetchDescriptor<CaptureSession> {
        FetchDescriptor<CaptureSession>(
            sortBy: [SortDescriptor(\.dateStarted, order: .reverse)]
        )
    }
}
