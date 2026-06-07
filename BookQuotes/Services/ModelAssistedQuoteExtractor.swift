import UIKit

struct ModelAssistedQuoteExtractor: QuoteExtracting {
    private let localExtractor: any QuoteExtracting
    private let remoteExtractor: any QuoteExtracting
    private let minimumLocalConfidence: Double

    init(
        localExtractor: any QuoteExtracting,
        remoteExtractor: any QuoteExtracting,
        minimumLocalConfidence: Double = 0.78
    ) {
        self.localExtractor = localExtractor
        self.remoteExtractor = remoteExtractor
        self.minimumLocalConfidence = minimumLocalConfidence
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        let localResult = try await localExtractor.extractQuotes(from: image, markings: markings)

        guard shouldUseRemoteFallback(localResult) else {
            return localResult
        }

        do {
            let remoteResult = try await remoteExtractor.extractQuotes(from: image, markings: markings)
            return remoteResult.isSuccessful ? remoteResult : localResult
        } catch {
            return localResult.isSuccessful ? localResult : try raise(error)
        }
    }

    private func shouldUseRemoteFallback(_ result: QuoteExtractionResult) -> Bool {
        !result.isSuccessful || result.averageConfidence < minimumLocalConfidence
    }

    private func raise(_ error: Error) throws -> QuoteExtractionResult {
        throw error
    }
}
