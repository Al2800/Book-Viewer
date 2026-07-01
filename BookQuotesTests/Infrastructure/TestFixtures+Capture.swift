import Foundation

@testable import BookQuotes

extension TestFixtures {
    // MARK: - Capture Sessions

    struct CaptureSessionBuilder {
        var book: Book? = nil
        var status: CaptureSession.SessionStatus = .capturing
        var dateStarted: Date = Date()
        var dateCompleted: Date? = nil
        var totalPages: Int = 0
        var processedPages: Int = 0
        var failedPages: Int = 0
        var captures: [PageCapture] = []

        func build() -> CaptureSession {
            let session = CaptureSession(book: book)
            session.status = status
            session.dateStarted = dateStarted
            session.dateCompleted = dateCompleted
            session.totalPages = totalPages
            session.processedPages = processedPages
            session.failedPages = failedPages
            session.captures = captures
            return session
        }
    }

    static func captureSession(
        _ configure: (inout CaptureSessionBuilder) -> Void = { _ in }
    ) -> CaptureSession {
        var builder = CaptureSessionBuilder()
        configure(&builder)
        return builder.build()
    }

    // MARK: - Page Captures

    struct PageCaptureBuilder {
        var imagePath: String = "captures/test/\(UUID().uuidString).jpg"
        var session: CaptureSession? = nil
        var orderIndex: Int = 0
        var status: PageCapture.CaptureStatus = .pending
        var errorMessage: String? = nil
        var dateCreated: Date = Date()
        var dateProcessed: Date? = nil
        var extractedQuoteCount: Int = 0
        var averageConfidence: Double? = nil
        var detectedPageNumber: Int? = nil
        var qualityScore: Double? = nil
        var qualityWarningsDismissed: Bool = false

        func build() -> PageCapture {
            let capture = PageCapture(imagePath: imagePath, session: session)
            capture.orderIndex = orderIndex
            capture.status = status
            capture.errorMessage = errorMessage
            capture.dateCreated = dateCreated
            capture.dateProcessed = dateProcessed
            capture.extractedQuoteCount = extractedQuoteCount
            capture.averageConfidence = averageConfidence
            capture.detectedPageNumber = detectedPageNumber
            capture.qualityScore = qualityScore
            capture.qualityWarningsDismissed = qualityWarningsDismissed
            return capture
        }
    }

    static func pageCapture(_ configure: (inout PageCaptureBuilder) -> Void = { _ in }) -> PageCapture {
        var builder = PageCaptureBuilder()
        configure(&builder)
        return builder.build()
    }

    // MARK: - Capture Queue Items

    struct CaptureQueueItemBuilder {
        var book: Book = TestFixtures.book()
        var imagePath: String = "CaptureQueue/\(UUID().uuidString).jpg"
        var thumbnailData: Data? = nil
        var priority: Int = 0
        var status: QueueItemStatus = .pending
        var retryCount: Int = 0
        var lastError: String? = nil
        var dateQueued: Date = Date()
        var dateLastAttempt: Date? = nil
        var dateCompleted: Date? = nil
        var extractedQuotes: [Quote]? = nil

        func build() -> CaptureQueueItem {
            let item = CaptureQueueItem(
                book: book,
                imagePath: imagePath,
                thumbnailData: thumbnailData,
                priority: priority
            )
            item.status = status
            item.retryCount = retryCount
            item.lastError = lastError
            item.dateQueued = dateQueued
            item.dateLastAttempt = dateLastAttempt
            item.dateCompleted = dateCompleted
            item.extractedQuotes = extractedQuotes
            return item
        }
    }

    static func captureQueueItem(
        _ configure: (inout CaptureQueueItemBuilder) -> Void = { _ in }
    ) -> CaptureQueueItem {
        var builder = CaptureQueueItemBuilder()
        configure(&builder)
        return builder.build()
    }
}
