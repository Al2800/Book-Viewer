import Foundation
import SwiftData
import UIKit

// MARK: - Batch Processing Service

/// Processes captured pages in parallel with rate limiting and progress tracking.
/// Handles batch extraction from CaptureSession with real-time status updates.
actor BatchProcessingService {

    // MARK: - Configuration

    struct Configuration {
        /// Maximum concurrent API requests
        var maxConcurrent: Int = 3

        /// Delay between requests to avoid rate limiting (seconds)
        var requestDelay: TimeInterval = 0.5

        /// Timeout for individual page processing (seconds)
        var pageTimeout: TimeInterval = 30

        /// Whether to stop on first failure
        var stopOnFirstFailure: Bool = false

        static let `default` = Configuration()

        /// Conservative settings for rate-limited scenarios
        static let conservative = Configuration(
            maxConcurrent: 2,
            requestDelay: 1.0,
            pageTimeout: 45
        )

        /// Aggressive settings for fast processing
        static let aggressive = Configuration(
            maxConcurrent: 5,
            requestDelay: 0.2,
            pageTimeout: 20
        )
    }

    // MARK: - Progress

    /// Real-time progress information
    struct BatchProgress: Sendable {
        let total: Int
        var completed: Int = 0
        var failed: Int = 0
        var currentlyProcessing: Set<UUID> = []

        var pending: Int {
            total - completed - failed
        }

        var percentComplete: Double {
            guard total > 0 else { return 0 }
            return Double(completed + failed) / Double(total)
        }

        var isComplete: Bool {
            pending == 0
        }

        var hasFailures: Bool {
            failed > 0
        }

        var summary: String {
            if isComplete {
                if failed == 0 {
                    return "Processed \(completed) pages successfully"
                } else {
                    return "Processed \(completed) pages, \(failed) failed"
                }
            } else {
                return "Processing... \(completed)/\(total) complete"
            }
        }
    }

    // MARK: - Result

    /// Result of processing a single page
    struct PageProcessingResult: Sendable {
        let captureId: UUID
        let success: Bool
        let extractedQuotes: [ExtractedQuoteData]
        let error: Error?
        let processingTime: TimeInterval

        var quoteCount: Int {
            extractedQuotes.count
        }
    }

    /// Result of processing entire batch
    struct BatchResult: Sendable {
        let session: CaptureSession
        let pageResults: [PageProcessingResult]
        let totalProcessingTime: TimeInterval

        var successCount: Int {
            pageResults.filter { $0.success }.count
        }

        var failureCount: Int {
            pageResults.filter { !$0.success }.count
        }

        var totalQuotes: Int {
            pageResults.reduce(0) { $0 + $1.quoteCount }
        }

        var isFullSuccess: Bool {
            failureCount == 0
        }
    }

    // MARK: - Properties

    private let configuration: Configuration
    private var progress: BatchProgress?
    private var isCancelled = false

    /// Progress update handler (called on main actor)
    private var progressHandler: ((BatchProgress) -> Void)?

    // MARK: - Initialization

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Processing

    /// Process all captures in a session
    /// - Parameters:
    ///   - session: The capture session to process
    ///   - markings: User's marking definitions for extraction
    ///   - onProgress: Progress callback (called on main actor)
    /// - Returns: Batch result with all page results
    func processSession(
        _ session: CaptureSession,
        markings: [MarkingDefinition],
        onProgress: ((BatchProgress) -> Void)? = nil
    ) async throws -> BatchResult {
        // Reset state
        isCancelled = false
        progress = BatchProgress(total: session.captures.count)
        progressHandler = onProgress

        let startTime = Date()

        // Update session status
        await MainActor.run {
            session.beginProcessing()
        }

        // Notify initial progress
        await notifyProgress()

        // Process captures in parallel with rate limiting
        let results = await processCaptures(
            session.captures,
            markings: markings
        )

        let totalTime = Date().timeIntervalSince(startTime)

        // Update session with final status
        await MainActor.run {
            for result in results {
                if result.success {
                    session.recordSuccess()
                } else {
                    session.recordFailure()
                }
            }
        }

        return BatchResult(
            session: session,
            pageResults: results,
            totalProcessingTime: totalTime
        )
    }

    /// Cancel ongoing processing
    func cancel() {
        isCancelled = true
    }

    // MARK: - Private Processing

    private func processCaptures(
        _ captures: [PageCapture],
        markings: [MarkingDefinition]
    ) async -> [PageProcessingResult] {
        var results: [PageProcessingResult] = []
        var captureIterator = captures.makeIterator()

        await withTaskGroup(of: PageProcessingResult.self) { group in
            var activeCount = 0

            // Seed initial batch
            while activeCount < configuration.maxConcurrent,
                  let capture = captureIterator.next() {
                group.addTask {
                    await self.processCapture(capture, markings: markings)
                }
                activeCount += 1

                // Update progress
                await updateProgress { $0.currentlyProcessing.insert(capture.id) }
            }

            // Process results and add new tasks
            for await result in group {
                results.append(result)
                activeCount -= 1

                // Update progress
                await updateProgress { progress in
                    progress.currentlyProcessing.remove(result.captureId)
                    if result.success {
                        progress.completed += 1
                    } else {
                        progress.failed += 1
                    }
                }

                // Check for cancellation or stop-on-failure
                if isCancelled {
                    group.cancelAll()
                    break
                }

                if configuration.stopOnFirstFailure && !result.success {
                    group.cancelAll()
                    break
                }

                // Add next capture if available
                if let nextCapture = captureIterator.next() {
                    // Rate limiting delay
                    try? await Task.sleep(for: .milliseconds(Int(configuration.requestDelay * 1000)))

                    group.addTask {
                        await self.processCapture(nextCapture, markings: markings)
                    }
                    activeCount += 1

                    await updateProgress { $0.currentlyProcessing.insert(nextCapture.id) }
                }
            }
        }

        return results
    }

    private func processCapture(
        _ capture: PageCapture,
        markings: [MarkingDefinition]
    ) async -> PageProcessingResult {
        let startTime = Date()

        // Update capture status
        await MainActor.run {
            capture.beginProcessing()
        }

        do {
            // Load image
            guard let image = capture.loadFullImage() else {
                throw ExtractionError.invalidImage
            }

            // Preprocess image
            let processed = try ImagePreprocessor.processForQuoteExtraction(image)

            // Build prompt
            let prompt = QuoteExtractionPromptBuilder.buildPrompt(markings: markings)

            // Call extraction (placeholder - will use GeminiService when available)
            let extractionResult = try await performExtraction(
                imageData: processed.data,
                prompt: prompt
            )

            // Update capture with results
            await MainActor.run {
                capture.completeProcessing(
                    quoteCount: extractionResult.quoteCount,
                    avgConfidence: extractionResult.averageConfidence,
                    pageNumber: extractionResult.pageNumber
                )
            }

            let processingTime = Date().timeIntervalSince(startTime)

            return PageProcessingResult(
                captureId: capture.id,
                success: true,
                extractedQuotes: extractionResult.quotes,
                error: nil,
                processingTime: processingTime
            )

        } catch {
            await MainActor.run {
                capture.failProcessing(error: error.localizedDescription)
            }

            let processingTime = Date().timeIntervalSince(startTime)

            return PageProcessingResult(
                captureId: capture.id,
                success: false,
                extractedQuotes: [],
                error: error,
                processingTime: processingTime
            )
        }
    }

    /// Placeholder extraction - will be replaced with GeminiService call
    private func performExtraction(
        imageData: Data,
        prompt: String
    ) async throws -> QuoteExtractionResult {
        // TODO: Replace with actual GeminiService call when available
        // For now, throw an error indicating service is not configured
        throw ExtractionError.authenticationRequired
    }

    // MARK: - Progress Management

    private func updateProgress(_ update: (inout BatchProgress) -> Void) async {
        guard var currentProgress = progress else { return }
        update(&currentProgress)
        progress = currentProgress
        await notifyProgress()
    }

    private func notifyProgress() async {
        guard let currentProgress = progress,
              let handler = progressHandler else { return }

        await MainActor.run {
            handler(currentProgress)
        }
    }
}

// MARK: - GeminiService Protocol

/// Protocol for Gemini API service (to be implemented)
protocol GeminiServiceProtocol: Sendable {
    func extractQuotes(
        from imageData: Data,
        prompt: String
    ) async throws -> QuoteExtractionResult

    func extractBookMetadata(
        from imageData: Data
    ) async throws -> BookMetadataResult
}

// MARK: - Batch Processing with GeminiService

extension BatchProcessingService {
    /// Process session with actual Gemini service
    func processSession(
        _ session: CaptureSession,
        markings: [MarkingDefinition],
        geminiService: any GeminiServiceProtocol,
        onProgress: ((BatchProgress) -> Void)? = nil
    ) async throws -> BatchResult {
        // This method would use the actual GeminiService
        // For now, delegate to placeholder implementation
        return try await processSession(session, markings: markings, onProgress: onProgress)
    }
}

// MARK: - Retry Logic

extension BatchProcessingService {
    /// Retry failed captures from a batch result
    func retryFailed(
        from result: BatchResult,
        markings: [MarkingDefinition],
        onProgress: ((BatchProgress) -> Void)? = nil
    ) async throws -> BatchResult {
        let failedCaptureIds = Set(result.pageResults.filter { !$0.success }.map { $0.captureId })
        let failedCaptures = result.session.captures.filter { failedCaptureIds.contains($0.id) }

        // Reset failed captures for retry
        await MainActor.run {
            for capture in failedCaptures {
                capture.resetForRetry()
            }
        }

        // Create a temporary session for retry
        let retrySession = result.session
        retrySession.totalPages = failedCaptures.count
        retrySession.processedPages = 0
        retrySession.failedPages = 0

        return try await processSession(retrySession, markings: markings, onProgress: onProgress)
    }
}
