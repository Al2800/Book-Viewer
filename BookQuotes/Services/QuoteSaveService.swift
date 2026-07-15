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
        let quote = try QuoteSaveDraft(
            extractedQuote: extractedQuote,
            book: book,
            sourceImage: sourceImage
        )
        .makeQuote()

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
