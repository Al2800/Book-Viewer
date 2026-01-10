import Foundation
import SwiftData
import UIKit

// MARK: - Quote Save Service

/// Service for persisting extracted quotes to the database.
/// Handles the critical path from AI-extracted text to saved library content.
/// Integrates with DuplicateDetector to warn users about potential duplicates.
@MainActor
final class QuoteSaveService {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let duplicateDetector: DuplicateDetector

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.duplicateDetector = DuplicateDetector(modelContext: modelContext)
    }

    /// Initialize with a custom duplicate detector configuration
    init(modelContext: ModelContext, duplicateConfig: DuplicateDetector.Configuration) {
        self.modelContext = modelContext
        self.duplicateDetector = DuplicateDetector(modelContext: modelContext, configuration: duplicateConfig)
    }

    // MARK: - Save Operations

    /// Save a single extracted quote to a book
    /// - Parameters:
    ///   - extractedQuote: The quote data from AI extraction
    ///   - book: The book to attach the quote to
    ///   - sourceImage: Optional source image data
    /// - Returns: The saved Quote model
    @discardableResult
    func save(
        _ extractedQuote: ExtractedQuote,
        to book: Book,
        sourceImage: Data? = nil
    ) throws -> Quote {
        // Create Quote model from extracted data
        let quote = Quote(
            text: extractedQuote.text,
            book: book,
            markingType: extractedQuote.markingType
        )

        // Set optional properties
        quote.pageNumber = extractedQuote.pageNumber
        quote.chapter = extractedQuote.chapter
        quote.marginNote = extractedQuote.marginNote
        quote.confidence = extractedQuote.confidence
        quote.sourceImageData = sourceImage
        quote.customMarkingDefinition = extractedQuote.customMarkingDefinition

        // Validate before saving
        try quote.validate()

        // Insert and save
        modelContext.insert(quote)

        // Update book's last quote date
        book.dateLastQuoteAdded = Date()

        try modelContext.save()

        HapticManager.quoteAdded()

        return quote
    }

    /// Save multiple extracted quotes to a book (batch operation)
    /// - Parameters:
    ///   - extractedQuotes: Array of quote data from AI extraction
    ///   - book: The book to attach the quotes to
    ///   - sourceImages: Optional dictionary mapping quote index to image data
    /// - Returns: Result containing saved quotes and any failures
    func saveMultiple(
        _ extractedQuotes: [ExtractedQuote],
        to book: Book,
        sourceImages: [Int: Data]? = nil
    ) -> BatchSaveResult {
        var savedQuotes: [Quote] = []
        var failures: [SaveFailure] = []

        for (index, extractedQuote) in extractedQuotes.enumerated() {
            do {
                let sourceImage = sourceImages?[index]
                let quote = try save(extractedQuote, to: book, sourceImage: sourceImage)
                savedQuotes.append(quote)
            } catch {
                failures.append(SaveFailure(
                    index: index,
                    extractedQuote: extractedQuote,
                    error: error
                ))
            }
        }

        // Attempt to persist all successful saves
        do {
            try modelContext.save()
        } catch {
            // If final save fails, all quotes may have failed
            // Return what we attempted
        }

        return BatchSaveResult(
            savedQuotes: savedQuotes,
            failures: failures,
            book: book
        )
    }

    /// Save quotes from a capture session
    /// - Parameters:
    ///   - session: The capture session with extracted quotes
    ///   - book: The book to attach quotes to
    /// - Returns: Batch save result
    func saveFromSession(
        _ session: CaptureSession,
        to book: Book
    ) -> BatchSaveResult {
        var allSavedQuotes: [Quote] = []
        var allFailures: [SaveFailure] = []

        // Process each completed capture
        for capture in session.captures where capture.status == .completed {
            // Get source image data if available
            let sourceImage = try? capture.loadFullImage()?.jpegData(compressionQuality: 0.7)

            // Note: In a real implementation, quotes would be stored with PageCapture
            // For now, this is a placeholder for the integration point
        }

        return BatchSaveResult(
            savedQuotes: allSavedQuotes,
            failures: allFailures,
            book: book
        )
    }

    // MARK: - Update Operations

    /// Update an existing quote
    /// - Parameters:
    ///   - quote: The quote to update
    ///   - newText: Optional new text
    ///   - newPageNumber: Optional new page number
    ///   - newMarginNote: Optional new margin note
    func update(
        _ quote: Quote,
        newText: String? = nil,
        newPageNumber: Int? = nil,
        newMarginNote: String? = nil
    ) throws {
        if let text = newText {
            quote.text = text
        }
        if let pageNumber = newPageNumber {
            quote.pageNumber = pageNumber
        }
        if let marginNote = newMarginNote {
            quote.marginNote = marginNote
        }

        quote.dateModified = Date()

        try quote.validate()
        try modelContext.save()
    }

    // MARK: - Delete Operations

    /// Delete a quote
    /// - Parameter quote: The quote to delete
    func delete(_ quote: Quote) throws {
        modelContext.delete(quote)
        try modelContext.save()
    }

    /// Delete multiple quotes
    /// - Parameter quotes: The quotes to delete
    func deleteMultiple(_ quotes: [Quote]) throws {
        for quote in quotes {
            modelContext.delete(quote)
        }
        try modelContext.save()
    }
}

// MARK: - Extracted Quote (Input Model)

/// Represents quote data extracted by AI before persistence.
/// This is the input format from the extraction service.
struct ExtractedQuote: Sendable {
    /// The extracted text content
    let text: String

    /// Type of marking detected
    let markingType: MarkingType

    /// AI confidence in the extraction (0.0-1.0)
    let confidence: Double?

    /// Detected page number
    let pageNumber: Int?

    /// Detected chapter
    let chapter: String?

    /// Transcribed margin note
    let marginNote: String?

    /// Custom marking definition if user has defined one
    let customMarkingDefinition: MarkingDefinition?

    /// Bounding box of the text in the source image (for future use)
    let boundingBox: CGRect?

    init(
        text: String,
        markingType: MarkingType = .underline,
        confidence: Double? = nil,
        pageNumber: Int? = nil,
        chapter: String? = nil,
        marginNote: String? = nil,
        customMarkingDefinition: MarkingDefinition? = nil,
        boundingBox: CGRect? = nil
    ) {
        self.text = text
        self.markingType = markingType
        self.confidence = confidence
        self.pageNumber = pageNumber
        self.chapter = chapter
        self.marginNote = marginNote
        self.customMarkingDefinition = customMarkingDefinition
        self.boundingBox = boundingBox
    }
}

// MARK: - Batch Save Result

/// Result of a batch save operation
struct BatchSaveResult: Sendable {
    /// Successfully saved quotes
    let savedQuotes: [Quote]

    /// Quotes that failed to save
    let failures: [SaveFailure]

    /// The book quotes were saved to
    let book: Book

    /// Whether all quotes were saved successfully
    var isFullSuccess: Bool {
        failures.isEmpty
    }

    /// Whether any quotes were saved
    var isPartialSuccess: Bool {
        !savedQuotes.isEmpty && !failures.isEmpty
    }

    /// Whether all quotes failed
    var isFullFailure: Bool {
        savedQuotes.isEmpty && !failures.isEmpty
    }

    /// Total number of quotes attempted
    var totalAttempted: Int {
        savedQuotes.count + failures.count
    }

    /// Success rate as percentage
    var successRate: Double {
        guard totalAttempted > 0 else { return 0 }
        return Double(savedQuotes.count) / Double(totalAttempted)
    }

    /// Human-readable summary
    var summary: String {
        if isFullSuccess {
            return "Saved \(savedQuotes.count) quote\(savedQuotes.count == 1 ? "" : "s")"
        } else if isFullFailure {
            return "Failed to save \(failures.count) quote\(failures.count == 1 ? "" : "s")"
        } else {
            return "Saved \(savedQuotes.count) of \(totalAttempted) quotes"
        }
    }
}

// MARK: - Save Failure

/// Details about a failed quote save
struct SaveFailure: Sendable {
    /// Index in the original array
    let index: Int

    /// The quote that failed to save
    let extractedQuote: ExtractedQuote

    /// The error that occurred
    let error: Error

    /// Human-readable error message
    var errorMessage: String {
        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }
        return error.localizedDescription
    }
}

// MARK: - Save Errors

enum QuoteSaveError: LocalizedError {
    case bookNotFound
    case invalidQuoteData(String)
    case persistenceFailed(Error)
    case duplicateQuote

    var errorDescription: String? {
        switch self {
        case .bookNotFound:
            return "The selected book could not be found"
        case .invalidQuoteData(let reason):
            return "Invalid quote data: \(reason)"
        case .persistenceFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .duplicateQuote:
            return "This quote already exists in your library"
        }
    }
}

// MARK: - Convenience Extensions

extension QuoteSaveService {
    /// Quick save for a simple text quote
    @discardableResult
    func quickSave(
        text: String,
        to book: Book,
        pageNumber: Int? = nil
    ) throws -> Quote {
        let extracted = ExtractedQuote(
            text: text,
            pageNumber: pageNumber
        )
        return try save(extracted, to: book)
    }
}

// MARK: - Duplicate Detection Integration

extension QuoteSaveService {
    /// Result of checking for duplicates before saving.
    struct PreSaveCheckResult {
        /// The extracted quote being checked
        let extractedQuote: ExtractedQuote

        /// The target book
        let book: Book

        /// Optional source image
        let sourceImage: Data?

        /// Duplicates found (empty if none)
        let duplicates: [DuplicateDetector.DuplicateResult]

        /// Whether any duplicates were found
        var hasDuplicates: Bool {
            !duplicates.isEmpty
        }

        /// Whether an exact duplicate was found
        var hasExactDuplicate: Bool {
            duplicates.contains { $0.isExactMatch }
        }

        /// The best match if any duplicates exist
        var bestMatch: DuplicateDetector.DuplicateResult? {
            duplicates.first
        }
    }

    /// Check for duplicates before saving a quote.
    /// Use this to show a warning dialog before calling save().
    /// - Parameters:
    ///   - extractedQuote: The quote to check
    ///   - book: The target book
    ///   - sourceImage: Optional source image (passed through for convenience)
    /// - Returns: PreSaveCheckResult with duplicate information
    func checkForDuplicatesBeforeSave(
        _ extractedQuote: ExtractedQuote,
        to book: Book,
        sourceImage: Data? = nil
    ) -> PreSaveCheckResult {
        let duplicates = duplicateDetector.checkForDuplicates(
            text: extractedQuote.text,
            inBook: book
        )

        return PreSaveCheckResult(
            extractedQuote: extractedQuote,
            book: book,
            sourceImage: sourceImage,
            duplicates: duplicates
        )
    }

    /// Save a quote after user has acknowledged duplicate warning.
    /// This is the same as save() but makes the intent explicit.
    /// - Parameter checkResult: The result from checkForDuplicatesBeforeSave
    /// - Returns: The saved Quote model
    @discardableResult
    func saveAfterDuplicateCheck(_ checkResult: PreSaveCheckResult) throws -> Quote {
        try save(
            checkResult.extractedQuote,
            to: checkResult.book,
            sourceImage: checkResult.sourceImage
        )
    }

    /// Check for duplicates in a batch of quotes.
    /// Useful for checking multiple extracted quotes at once.
    /// - Parameters:
    ///   - extractedQuotes: The quotes to check
    ///   - book: The target book
    /// - Returns: Array of check results for each quote
    func checkBatchForDuplicates(
        _ extractedQuotes: [ExtractedQuote],
        to book: Book
    ) -> [PreSaveCheckResult] {
        let texts = extractedQuotes.map { $0.text }
        let batchResults = duplicateDetector.checkBatchForDuplicates(texts: texts, inBook: book)

        return extractedQuotes.map { quote in
            PreSaveCheckResult(
                extractedQuote: quote,
                book: book,
                sourceImage: nil,
                duplicates: batchResults[quote.text] ?? []
            )
        }
    }

    /// Quick check if a quote would be a duplicate.
    /// More efficient than full checkForDuplicatesBeforeSave when you just need yes/no.
    func wouldBeDuplicate(text: String, inBook book: Book) -> Bool {
        duplicateDetector.hasDuplicates(text: text, inBook: book)
    }

    /// Find an exact duplicate if one exists.
    /// Returns nil if no exact match (>99% similarity) is found.
    func findExactDuplicate(text: String, inBook book: Book) -> Quote? {
        duplicateDetector.findExactDuplicate(text: text, inBook: book)
    }
}
