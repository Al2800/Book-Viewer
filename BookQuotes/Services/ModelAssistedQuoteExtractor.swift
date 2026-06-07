import UIKit

struct ModelAssistedQuoteExtractor: QuoteExtracting {
    private let localExtractor: any QuoteExtracting
    private let remoteExtractor: any QuoteExtracting

    init(
        localExtractor: any QuoteExtracting,
        remoteExtractor: any QuoteExtracting
    ) {
        self.localExtractor = localExtractor
        self.remoteExtractor = remoteExtractor
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        do {
            let remoteResult = try await remoteExtractor.extractQuotes(from: image, markings: markings)

            guard !remoteResult.isSuccessful else {
                return remoteResult
            }

            let localResult = try await localExtractor.extractQuotes(from: image, markings: markings)
            return localResult.isSuccessful ? localResult : remoteResult
        } catch {
            let localResult = try? await localExtractor.extractQuotes(from: image, markings: markings)
            if let localResult, localResult.isSuccessful {
                return localResult
            }
            throw error
        }
    }
}
