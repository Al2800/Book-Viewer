import UIKit

struct QuoteExtractionPipeline: QuoteExtracting {
    private let extractor: any QuoteExtracting

    init(
        localExtractor: any QuoteExtracting,
        remoteExtractor: any QuoteExtracting
    ) {
        self.extractor = ModelAssistedQuoteExtractor(
            localExtractor: localExtractor,
            remoteExtractor: remoteExtractor
        )
    }

    private init(extractor: any QuoteExtracting) {
        self.extractor = extractor
    }

    static func live(authService: AuthService) -> QuoteExtractionPipeline {
        if let scenario = UITestConfiguration.mockExtractionScenario {
            return QuoteExtractionPipeline(extractor: UITestQuoteExtractor(scenario: scenario))
        }

        return QuoteExtractionPipeline(
            localExtractor: OnDeviceQuoteExtractor(),
            remoteExtractor: RemoteModelQuoteExtractor(authService: authService)
        )
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        try await extractor.extractQuotes(from: image, markings: markings)
    }
}

private struct UITestQuoteExtractor: QuoteExtracting {
    let scenario: String

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        let confidence = UITestConfiguration.shouldMockLowConfidence ? 0.48 : 0.94
        let marginNote = UITestConfiguration.shouldMockLowConfidence ? "hard to read" : nil

        switch scenario {
        case "local-fallback":
            return QuoteExtractionResult(
                quotes: [
                    ExtractedQuoteData(
                        text: "An on-device fallback quote used for review testing.",
                        pageNumber: 38,
                        marginNote: "review locally",
                        markingType: "highlight",
                        confidence: 0.74,
                        extractionSource: .onDevice
                    )
                ],
                pageNumber: 38,
                processingNotes: "UI test mock extraction",
                fallbackReason: .remoteUnavailable
            )
        case "mixed":
            return QuoteExtractionResult(
                quotes: [
                    ExtractedQuoteData(
                        text: "A model-assisted quote used for review testing.",
                        pageNumber: 38,
                        marginNote: marginNote,
                        markingType: "underline",
                        confidence: confidence,
                        extractionSource: .modelAssisted
                    ),
                    ExtractedQuoteData(
                        text: "An on-device quote used for review testing.",
                        pageNumber: 38,
                        marginNote: "review locally",
                        markingType: "highlight",
                        confidence: 0.74,
                        extractionSource: .onDevice
                    )
                ],
                pageNumber: 38,
                processingNotes: "UI test mock extraction"
            )
        default:
            return QuoteExtractionResult(
                quotes: [
                    ExtractedQuoteData(
                        text: "A model-assisted quote used for review testing.",
                        pageNumber: 38,
                        marginNote: marginNote,
                        markingType: "underline",
                        confidence: confidence,
                        extractionSource: .modelAssisted
                    )
                ],
                pageNumber: 38,
                processingNotes: "UI test mock extraction"
            )
        }
    }
}

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
            return localResult.isSuccessful
                ? localResult.withFallbackReason(.remoteReturnedNoQuotes)
                : remoteResult
        } catch {
            let localResult = try? await localExtractor.extractQuotes(from: image, markings: markings)
            if let localResult, localResult.isSuccessful {
                return localResult.withFallbackReason(.from(error))
            }
            throw error
        }
    }
}
