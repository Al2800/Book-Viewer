import Foundation
import SwiftData
import UIKit

// MARK: - CaptureQueueItem

/// Persisted queue item for offline capture processing.
/// Stores captured images locally and tracks processing status until
/// network connectivity allows AI extraction.
@Model
final class CaptureQueueItem {

    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - References

    /// The book this capture belongs to
    var book: Book?

    // MARK: - Image Storage

    /// Relative path to the captured image in Documents/CaptureQueue/
    var imagePath: String

    /// Compressed thumbnail for quick display in queue UI
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    // MARK: - Status

    /// Current processing status
    var status: QueueItemStatus

    /// Higher priority items are processed first (default 0)
    var priority: Int

    /// Number of processing attempts
    var retryCount: Int

    /// Maximum retries before marking as failed
    static let maxRetries = 3

    /// Last error message if processing failed
    var lastError: String?

    // MARK: - Timestamps

    /// When the item was added to the queue
    var dateQueued: Date

    /// When the last processing attempt occurred
    var dateLastAttempt: Date?

    /// When processing completed successfully
    var dateCompleted: Date?

    // MARK: - Results

    /// Quotes extracted from this capture (set after successful processing)
    @Relationship(deleteRule: .nullify)
    var extractedQuotes: [Quote]?

    // MARK: - Initialization

    init(
        book: Book,
        imagePath: String,
        thumbnailData: Data? = nil,
        priority: Int = 0
    ) {
        self.id = UUID()
        self.book = book
        self.imagePath = imagePath
        self.thumbnailData = thumbnailData
        self.status = .pending
        self.priority = priority
        self.retryCount = 0
        self.dateQueued = Date()
    }

    // MARK: - Computed Properties

    /// Full path to the image file
    var fullImagePath: URL {
        CaptureQueueItem.queueDirectory.appendingPathComponent(imagePath)
    }

    /// Whether this item can be retried
    var canRetry: Bool {
        status == .failed && retryCount < CaptureQueueItem.maxRetries
    }

    /// Whether this item is actionable (pending or retryable)
    var isActionable: Bool {
        status == .pending || canRetry
    }

    /// Human-readable status description
    var statusDescription: String {
        switch status {
        case .pending:
            return "Waiting to process"
        case .processing:
            return "Processing..."
        case .completed:
            return "Completed"
        case .failed:
            if canRetry {
                return "Failed (will retry)"
            } else {
                return "Failed"
            }
        case .cancelled:
            return "Cancelled"
        }
    }

    /// Time since queued as human-readable string
    var queuedAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateQueued, relativeTo: Date())
    }

    // MARK: - Static Properties

    /// Directory for storing queue images
    static var queueDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let queueDir = documents.appendingPathComponent("CaptureQueue", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: queueDir, withIntermediateDirectories: true)

        return queueDir
    }
}

// MARK: - QueueItemStatus

/// Status of a queued capture item
enum QueueItemStatus: String, Codable, CaseIterable {
    /// Waiting for network connectivity to process
    case pending

    /// Currently being processed by the extraction service
    case processing

    /// Successfully processed and quotes extracted
    case completed

    /// Processing failed (check lastError for details)
    case failed

    /// User cancelled this item
    case cancelled

    /// SF Symbol for status
    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle"
        }
    }

    /// Color for status indicator
    var color: String {
        switch self {
        case .pending: return "secondary"
        case .processing: return "accent"
        case .completed: return "success"
        case .failed: return "error"
        case .cancelled: return "secondary"
        }
    }

    /// Whether this status indicates a terminal state
    var isTerminal: Bool {
        switch self {
        case .pending, .processing:
            return false
        case .completed, .failed, .cancelled:
            return true
        }
    }
}

// MARK: - Status Transitions

extension CaptureQueueItem {
    /// Mark item as currently processing
    func markProcessing() {
        status = .processing
        dateLastAttempt = Date()
    }

    /// Mark item as successfully completed
    /// - Parameter quotes: The extracted quotes to associate
    func markCompleted(quotes: [Quote]) {
        status = .completed
        dateCompleted = Date()
        extractedQuotes = quotes
        lastError = nil
    }

    /// Mark item as failed
    /// - Parameter error: The error that caused the failure
    func markFailed(error: Error) {
        retryCount += 1
        lastError = error.localizedDescription

        if retryCount >= CaptureQueueItem.maxRetries {
            status = .failed
        } else {
            // Return to pending for retry
            status = .pending
        }
    }

    /// Mark item as permanently failed (no more retries)
    func markPermanentlyFailed(error: Error) {
        status = .failed
        lastError = error.localizedDescription
        retryCount = CaptureQueueItem.maxRetries
    }

    /// Cancel this queue item
    func cancel() {
        status = .cancelled
        dateCompleted = Date()
    }

    /// Reset item to pending for manual retry
    func resetForRetry() {
        status = .pending
        lastError = nil
        // Don't reset retryCount to track total attempts
    }
}

// MARK: - Image Management

extension CaptureQueueItem {
    /// Load the full image from disk
    /// - Returns: The image or nil if loading fails
    func loadFullImage() -> UIImage? {
        UIImage(contentsOfFile: fullImagePath.path)
    }

    /// Load the thumbnail, falling back to full image if needed
    /// - Returns: Thumbnail image or nil
    func loadThumbnail() -> UIImage? {
        if let thumbnailData = thumbnailData {
            return UIImage(data: thumbnailData)
        }
        // Fall back to resized full image
        guard let fullImage = loadFullImage() else {
            return nil
        }
        return fullImage.preparingThumbnail(of: CGSize(width: 100, height: 100))
    }

    /// Delete the associated image file from disk
    func deleteImageFile() {
        try? FileManager.default.removeItem(at: fullImagePath)
    }

    /// Save an image to the queue directory
    /// - Parameters:
    ///   - image: The image to save
    ///   - quality: JPEG compression quality (default 0.7)
    /// - Returns: The relative path to the saved file
    static func saveImage(_ image: UIImage, quality: CGFloat = 0.7) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else {
            return nil
        }

        let filename = "\(UUID().uuidString).jpg"
        let path = queueDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: path)
            return filename
        } catch {
            return nil
        }
    }

    /// Generate a thumbnail from an image
    /// - Parameters:
    ///   - image: The source image
    ///   - maxSize: Maximum dimension for thumbnail
    /// - Returns: Compressed thumbnail data
    static func generateThumbnail(from image: UIImage, maxSize: CGFloat = 100) -> Data? {
        let thumbnail = image.preparingThumbnail(of: CGSize(width: maxSize, height: maxSize))
        return thumbnail?.jpegData(compressionQuality: 0.5)
    }
}

// MARK: - Cleanup

extension CaptureQueueItem {
    /// Items older than this are eligible for automatic cleanup
    static let completedRetentionHours: TimeInterval = 24

    /// Whether this item is eligible for automatic cleanup
    var isEligibleForCleanup: Bool {
        guard status == .completed || status == .cancelled else {
            return false
        }

        guard let completed = dateCompleted else {
            // Cancelled items without completion date can be cleaned up
            return status == .cancelled
        }

        let hoursAgo = Date().timeIntervalSince(completed) / 3600
        return hoursAgo >= CaptureQueueItem.completedRetentionHours
    }
}

// MARK: - Query Descriptors

extension CaptureQueueItem {
    /// Fetch all pending items sorted by priority then date
    static var pendingDescriptor: FetchDescriptor<CaptureQueueItem> {
        var descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { item in
                item.status == .pending
            },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.dateQueued, order: .forward)
            ]
        )
        return descriptor
    }

    /// Fetch all items for a specific book
    static func descriptorForBook(_ book: Book) -> FetchDescriptor<CaptureQueueItem> {
        let bookId = book.id
        return FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { item in
                item.book?.id == bookId
            },
            sortBy: [SortDescriptor(\.dateQueued, order: .reverse)]
        )
    }

    /// Fetch items eligible for cleanup
    static var cleanupDescriptor: FetchDescriptor<CaptureQueueItem> {
        let cutoffDate = Date().addingTimeInterval(-completedRetentionHours * 3600)
        return FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { item in
                (item.status == .completed || item.status == .cancelled) &&
                (item.dateCompleted ?? cutoffDate) < cutoffDate
            }
        )
    }

    /// Fetch all permanently failed items
    static var failedDescriptor: FetchDescriptor<CaptureQueueItem> {
        FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { item in
                item.status == .failed
            },
            sortBy: [SortDescriptor(\.dateQueued, order: .reverse)]
        )
    }
}
