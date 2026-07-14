import Foundation
import SwiftData

struct CaptureQueueItemProcessor {
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

        let quotes = result.quotes.map { extractedQuote in
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
            return quote
        }

        item.markCompleted(quotes: quotes)
        try context.save()

        if item.deleteImageFile() {
            try? context.save()
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
