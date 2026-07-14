import Foundation
import SwiftData

struct CaptureQueueItemProcessor {
    private static let duplicateSimilarityThreshold = 0.85

    let modelContainer: ModelContainer
    let quoteExtractor: any QuoteExtracting

    func process(
        itemId: UUID,
        onStateChanged: () async -> Void
    ) async -> CaptureQueueProcessingOutcome {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CaptureQueueItem>(
            predicate: #Predicate<CaptureQueueItem> { $0.id == itemId }
        )

        guard let item = try? context.fetch(descriptor).first else {
            return .missing
        }

        guard item.status != .completed else {
            return .completed
        }

        if let resolvedQuotes = item.extractedQuotes, !resolvedQuotes.isEmpty {
            item.markCompleted(quotes: resolvedQuotes)
            do {
                try context.save()

                if item.deleteImageFile() {
                    try context.save()
                }
            } catch {
                item.markFailed(error: error)
                try? context.save()
                await onStateChanged()

                return .failed(
                    itemId: item.id,
                    retryCount: item.retryCount,
                    canRetry: item.canRetry
                )
            }

            await onStateChanged()
            return .completed
        }

        item.markProcessing()
        try? context.save()
        await onStateChanged()

        do {
            try await extractAndSaveQuotes(for: item, in: context)
            await onStateChanged()
            return .completed
        } catch {
            item.markFailed(error: error)
            try? context.save()
            await onStateChanged()

            return .failed(
                itemId: item.id,
                retryCount: item.retryCount,
                canRetry: item.canRetry
            )
        }
    }

    private func extractAndSaveQuotes(
        for item: CaptureQueueItem,
        in context: ModelContext
    ) async throws {
        guard let image = item.loadFullImage() else {
            throw QueueError.imageLoadFailed
        }

        let markings = try fetchEnabledMarkingPrompts(in: context)
        let result = try await quoteExtractor.extractQuotes(from: image, markings: markings)

        guard let book = item.book else {
            throw QueueError.bookNotFound
        }

        var resolvedQuotes = try existingQuotes(for: book, in: context)
        var quotesByNormalizedText: [String: Quote] = [:]
        for quote in resolvedQuotes {
            quotesByNormalizedText[normalizedText(quote.text), default: quote] = quote
        }

        let quotes: [Quote] = result.quotes.compactMap { extractedQuote -> Quote? in
            let normalizedQuote = normalizedText(extractedQuote.text)
            guard !normalizedQuote.isEmpty else { return nil }

            if let existingQuote = quotesByNormalizedText[normalizedQuote] {
                return existingQuote
            }

            if let existingQuote = duplicateQuote(
                matching: normalizedQuote,
                in: resolvedQuotes
            ) {
                return existingQuote
            }

            let extractedData = extractedQuote.toExtractedQuote()
            let quote = Quote(
                text: extractedQuote.text,
                book: book,
                markingType: extractedData.markingType
            )
            quote.pageNumber = extractedQuote.pageNumber
            quote.marginNote = extractedQuote.marginNote
            quote.confidence = extractedQuote.confidence
            context.insert(quote)
            resolvedQuotes.append(quote)
            quotesByNormalizedText[normalizedQuote] = quote
            return quote
        }

        item.markCompleted(quotes: quotes)
        try context.save()

        if item.deleteImageFile() {
            try? context.save()
        }
    }

    private func existingQuotes(for book: Book, in context: ModelContext) throws -> [Quote] {
        let bookId = book.id
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.book?.id == bookId }
        )
        return try context.fetch(descriptor)
    }

    private func normalizedText(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func duplicateQuote(matching candidateText: String, in quotes: [Quote]) -> Quote? {
        quotes.first { quote in
            let existingText = normalizedText(quote.text)
            guard !existingText.isEmpty else { return false }
            return levenshteinSimilarity(candidateText, existingText)
                >= Self.duplicateSimilarityThreshold
        }
    }

    private func fetchEnabledMarkingPrompts(
        in context: ModelContext
    ) throws -> [QuoteExtractionPromptBuilder.MarkingPrompt] {
        let descriptor = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate<MarkingDefinition> { $0.isEnabled }
        )
        return try context.fetch(descriptor).map {
            QuoteExtractionPromptBuilder.MarkingPrompt($0)
        }
    }
}

enum CaptureQueueProcessingOutcome {
    case completed
    case failed(itemId: UUID, retryCount: Int, canRetry: Bool)
    case missing

    var retryRequest: CaptureQueueRetryRequest? {
        guard case let .failed(itemId, retryCount, true) = self else {
            return nil
        }

        return CaptureQueueRetryRequest(itemId: itemId, retryCount: retryCount)
    }
}

struct CaptureQueueRetryRequest: Equatable {
    let itemId: UUID
    let retryCount: Int
}
