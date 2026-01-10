import Foundation
import SwiftData

// MARK: - DuplicateDetector

/// Detects duplicate quotes using Levenshtein distance fuzzy matching.
/// Uses an actor to ensure thread-safe access to the model context.
@MainActor
final class DuplicateDetector {

    // MARK: - Types

    /// Result of a duplicate check containing match details.
    struct DuplicateResult: Sendable, Identifiable {
        let id: UUID
        let existingQuoteId: UUID
        let existingQuoteText: String
        let similarityScore: Double
        let isExactMatch: Bool

        /// Human-readable similarity percentage (e.g., "92%")
        var similarityPercentage: String {
            String(format: "%.0f%%", similarityScore * 100)
        }
    }

    /// Configuration for duplicate detection behavior.
    struct Configuration: Sendable {
        /// Minimum similarity score to consider a match (0.0 to 1.0)
        var similarityThreshold: Double

        /// Threshold for considering a match "exact" (default 0.99)
        var exactMatchThreshold: Double

        /// Maximum number of results to return
        var maxResults: Int

        /// Whether to use case-insensitive comparison
        var caseInsensitive: Bool

        static let `default` = Configuration(
            similarityThreshold: 0.85,
            exactMatchThreshold: 0.99,
            maxResults: 10,
            caseInsensitive: true
        )

        static let strict = Configuration(
            similarityThreshold: 0.95,
            exactMatchThreshold: 0.99,
            maxResults: 5,
            caseInsensitive: true
        )

        static let loose = Configuration(
            similarityThreshold: 0.70,
            exactMatchThreshold: 0.99,
            maxResults: 20,
            caseInsensitive: true
        )
    }

    // MARK: - Properties

    private let modelContext: ModelContext
    private let configuration: Configuration

    // MARK: - Initialization

    /// Initialize with a model context and optional configuration.
    /// - Parameters:
    ///   - modelContext: SwiftData model context for fetching quotes
    ///   - configuration: Detection configuration (default: .default)
    init(
        modelContext: ModelContext,
        configuration: Configuration = .default
    ) {
        self.modelContext = modelContext
        self.configuration = configuration
    }

    // MARK: - Public API

    /// Check if the given text matches any existing quotes.
    /// - Parameters:
    ///   - text: The quote text to check
    ///   - book: Optional book to limit search scope (nil = all books)
    /// - Returns: Array of duplicate results sorted by similarity (highest first)
    func checkForDuplicates(
        text: String,
        inBook book: Book? = nil
    ) -> [DuplicateResult] {
        let quotes = fetchQuotes(book: book)
        let normalizedText = normalizeText(text)

        var results: [DuplicateResult] = []

        for quote in quotes {
            let normalizedQuoteText = normalizeText(quote.text)
            let similarity = calculateSimilarity(normalizedText, normalizedQuoteText)

            guard similarity >= configuration.similarityThreshold else { continue }

            let result = DuplicateResult(
                id: UUID(),
                existingQuoteId: quote.id,
                existingQuoteText: quote.text,
                similarityScore: similarity,
                isExactMatch: similarity >= configuration.exactMatchThreshold
            )
            results.append(result)
        }

        // Sort by similarity (highest first) and limit results
        return results
            .sorted { $0.similarityScore > $1.similarityScore }
            .prefix(configuration.maxResults)
            .map { $0 }
    }

    /// Quick check if any duplicates exist for the given text.
    /// More efficient than checkForDuplicates when you only need yes/no.
    /// - Parameters:
    ///   - text: The quote text to check
    ///   - book: Optional book to limit search scope
    /// - Returns: true if at least one duplicate exists
    func hasDuplicates(text: String, inBook book: Book? = nil) -> Bool {
        let quotes = fetchQuotes(book: book)
        let normalizedText = normalizeText(text)

        for quote in quotes {
            let normalizedQuoteText = normalizeText(quote.text)
            let similarity = calculateSimilarity(normalizedText, normalizedQuoteText)

            if similarity >= configuration.similarityThreshold {
                return true
            }
        }

        return false
    }

    /// Check if an exact duplicate exists (>99% similarity).
    /// - Parameters:
    ///   - text: The quote text to check
    ///   - book: Optional book to limit search scope
    /// - Returns: The existing quote if an exact match is found
    func findExactDuplicate(text: String, inBook book: Book? = nil) -> Quote? {
        let quotes = fetchQuotes(book: book)
        let normalizedText = normalizeText(text)

        for quote in quotes {
            let normalizedQuoteText = normalizeText(quote.text)
            let similarity = calculateSimilarity(normalizedText, normalizedQuoteText)

            if similarity >= configuration.exactMatchThreshold {
                return quote
            }
        }

        return nil
    }

    /// Get the best matching quote for the given text.
    /// - Parameters:
    ///   - text: The quote text to match
    ///   - book: Optional book to limit search scope
    /// - Returns: The best match if above threshold, nil otherwise
    func findBestMatch(text: String, inBook book: Book? = nil) -> DuplicateResult? {
        checkForDuplicates(text: text, inBook: book).first
    }

    // MARK: - Private Helpers

    private func fetchQuotes(book: Book?) -> [Quote] {
        var descriptor = FetchDescriptor<Quote>()

        if let book = book {
            let bookId = book.id
            descriptor.predicate = #Predicate<Quote> { quote in
                quote.book?.id == bookId
            }
        }

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func normalizeText(_ text: String) -> String {
        var normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if configuration.caseInsensitive {
            normalized = normalized.lowercased()
        }

        // Normalize whitespace
        normalized = normalized
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return normalized
    }

    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        // Use global levenshteinSimilarity function
        levenshteinSimilarity(s1, s2)
    }
}

// MARK: - DuplicateDetector + Batch

extension DuplicateDetector {
    /// Check multiple texts for duplicates in a single pass.
    /// More efficient than calling checkForDuplicates repeatedly.
    /// - Parameters:
    ///   - texts: Array of quote texts to check
    ///   - book: Optional book to limit search scope
    /// - Returns: Dictionary mapping input text to array of duplicates
    func checkBatchForDuplicates(
        texts: [String],
        inBook book: Book? = nil
    ) -> [String: [DuplicateResult]] {
        let quotes = fetchQuotes(book: book)
        var results: [String: [DuplicateResult]] = [:]

        for text in texts {
            let normalizedText = normalizeText(text)
            var textResults: [DuplicateResult] = []

            for quote in quotes {
                let normalizedQuoteText = normalizeText(quote.text)
                let similarity = calculateSimilarity(normalizedText, normalizedQuoteText)

                guard similarity >= configuration.similarityThreshold else { continue }

                let result = DuplicateResult(
                    id: UUID(),
                    existingQuoteId: quote.id,
                    existingQuoteText: quote.text,
                    similarityScore: similarity,
                    isExactMatch: similarity >= configuration.exactMatchThreshold
                )
                textResults.append(result)
            }

            results[text] = textResults
                .sorted { $0.similarityScore > $1.similarityScore }
                .prefix(configuration.maxResults)
                .map { $0 }
        }

        return results
    }
}
