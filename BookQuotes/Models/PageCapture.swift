import Foundation
import SwiftData
import UIKit

// MARK: - Page Capture Model

/// Represents a single captured page within a batch session.
/// Stores the image path, thumbnail, processing state, and extracted quotes.
@Model
final class PageCapture {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Image Storage

    /// File path to full-resolution image in Documents directory
    /// Format: "captures/{sessionId}/{uuid}.jpg"
    var imagePath: String

    /// Small preview thumbnail for quick display (embedded)
    /// Typically 200x300 pixels, JPEG compressed
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    // MARK: - Ordering

    /// Position in the capture session (0-indexed)
    var orderIndex: Int

    // MARK: - Processing State

    /// Current processing status
    var status: CaptureStatus

    /// Error message if processing failed
    var errorMessage: String?

    // MARK: - Timing

    /// When the page was captured
    var dateCreated: Date

    /// When processing completed
    var dateProcessed: Date?

    // MARK: - AI Results

    /// Number of quotes extracted from this page
    var extractedQuoteCount: Int

    /// Average confidence of extracted quotes
    var averageConfidence: Double?

    /// Detected page number (if any)
    var detectedPageNumber: Int?

    /// JSON-encoded extracted quote data from processing
    /// Stored as Data for SwiftData compatibility
    @Attribute(.externalStorage)
    var extractedQuotesData: Data?

    // MARK: - Quality Metrics (cached from analysis)

    /// Image quality score at capture time
    var qualityScore: Double?

    /// Whether quality warnings were dismissed
    var qualityWarningsDismissed: Bool

    // MARK: - Relationships

    /// The session this capture belongs to
    var session: CaptureSession?

    // MARK: - Computed Properties

    /// Full file URL for the image
    var imageURL: URL? {
        guard !imagePath.isEmpty else { return nil }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(imagePath)
    }

    /// Whether this capture can be retried
    var canRetry: Bool {
        status == .failed
    }

    /// Whether processing is in progress
    var isProcessing: Bool {
        status == .processing
    }

    /// Human-readable status description
    var statusDescription: String {
        switch status {
        case .pending:
            return "Waiting to process"
        case .processing:
            return "Processing..."
        case .completed:
            return "\(extractedQuoteCount) quote\(extractedQuoteCount == 1 ? "" : "s") extracted"
        case .failed:
            return errorMessage ?? "Processing failed"
        }
    }

    // MARK: - Initialization

    init(imagePath: String, session: CaptureSession? = nil) {
        self.id = UUID()
        self.imagePath = imagePath
        self.orderIndex = 0
        self.status = .pending
        self.dateCreated = Date()
        self.extractedQuoteCount = 0
        self.qualityWarningsDismissed = false
        self.session = session
    }

    // MARK: - Processing Management

    /// Begin processing this capture
    func beginProcessing() {
        guard status == .pending else { return }
        status = .processing
    }

    /// Mark processing as successful
    func completeProcessing(quoteCount: Int, avgConfidence: Double?, pageNumber: Int?) {
        status = .completed
        dateProcessed = Date()
        extractedQuoteCount = quoteCount
        averageConfidence = avgConfidence
        detectedPageNumber = pageNumber
        errorMessage = nil
    }

    /// Mark processing as failed
    func failProcessing(error: String) {
        status = .failed
        dateProcessed = Date()
        errorMessage = error
    }

    /// Reset for retry
    func resetForRetry() {
        guard status == .failed else { return }
        status = .pending
        dateProcessed = nil
        errorMessage = nil
        extractedQuoteCount = 0
        averageConfidence = nil
        extractedQuotesData = nil
    }

    // MARK: - Extraction Results Management

    /// Store extracted quote data from processing
    func storeExtractedQuotes(_ quotes: [ExtractedQuoteData]) {
        let encoder = JSONEncoder()
        extractedQuotesData = try? encoder.encode(quotes)
        extractedQuoteCount = quotes.count

        // Calculate average confidence from quotes that have confidence values
        let confidenceValues = quotes.compactMap { $0.confidence }
        averageConfidence = confidenceValues.isEmpty ? nil :
            confidenceValues.reduce(0, +) / Double(confidenceValues.count)
    }

    /// Retrieve stored extracted quotes
    func loadExtractedQuotes() -> [ExtractedQuoteData] {
        guard let data = extractedQuotesData else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([ExtractedQuoteData].self, from: data)) ?? []
    }

    // MARK: - Image Management

    /// Load the thumbnail as UIImage
    func loadThumbnail() -> UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }

    /// Load the full image from disk
    func loadFullImage() -> UIImage? {
        guard let url = imageURL else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// Delete the image file from disk
    func deleteImageFile() {
        guard let url = imageURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Capture Status

extension PageCapture {
    /// Processing status of a page capture
    enum CaptureStatus: String, Codable, CaseIterable {
        /// Waiting to be processed
        case pending

        /// Currently being processed
        case processing

        /// Successfully processed
        case completed

        /// Processing failed
        case failed

        var icon: String {
            switch self {
            case .pending: return "clock"
            case .processing: return "arrow.trianglehead.2.clockwise"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .pending: return "textSecondary"
            case .processing: return "brand"
            case .completed: return "success"
            case .failed: return "error"
            }
        }
    }
}

// MARK: - Image Storage Utilities

extension PageCapture {
    private static func documentsDirectory() throws -> URL {
        guard let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first else {
            throw CocoaError(.fileNoSuchFile)
        }

        return documentsURL
    }

    /// Generate a unique file path for a new capture
    /// - Parameter sessionId: The session this capture belongs to
    /// - Returns: Relative path from Documents directory
    static func generateImagePath(sessionId: UUID) -> String {
        let filename = UUID().uuidString + ".jpg"
        return "captures/\(sessionId.uuidString)/\(filename)"
    }

    /// Ensure the directory exists for a given session
    static func ensureDirectory(for sessionId: UUID) throws {
        let documentsURL = try documentsDirectory()

        let directoryURL = documentsURL
            .appendingPathComponent("captures")
            .appendingPathComponent(sessionId.uuidString)

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    /// Save image data to the designated path
    /// - Parameters:
    ///   - data: JPEG image data
    ///   - path: Relative path from Documents
    static func saveImage(_ data: Data, to path: String) throws {
        let documentsURL = try documentsDirectory()

        let fileURL = documentsURL.appendingPathComponent(path)
        try data.write(to: fileURL)
    }
}

// MARK: - Query Descriptors

extension PageCapture {
    /// Captures pending processing
    static var pending: FetchDescriptor<PageCapture> {
        FetchDescriptor<PageCapture>(
            predicate: #Predicate { $0.status == .pending },
            sortBy: [SortDescriptor(\.orderIndex)]
        )
    }

    /// Failed captures that can be retried
    static var failed: FetchDescriptor<PageCapture> {
        FetchDescriptor<PageCapture>(
            predicate: #Predicate { $0.status == .failed },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
    }
}
