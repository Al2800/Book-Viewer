import UIKit

struct QuoteExtractionPipeline: QuoteExtracting {
    private let extractor: any QuoteExtracting
    private let localOnlyReason: ExtractionFallbackReason?

    init(
        localExtractor: any QuoteExtracting,
        remoteExtractor: any QuoteExtracting,
        isRemoteProcessingEnabled: Bool = false
    ) {
        self.extractor = isRemoteProcessingEnabled
            ? ModelAssistedQuoteExtractor(
                localExtractor: localExtractor,
                remoteExtractor: remoteExtractor
            )
            : localExtractor
        self.localOnlyReason = isRemoteProcessingEnabled ? nil : .remoteProcessingDisabled
    }

    private init(
        extractor: any QuoteExtracting,
        localOnlyReason: ExtractionFallbackReason? = nil
    ) {
        self.extractor = extractor
        self.localOnlyReason = localOnlyReason
    }

    static func live(authService: AuthService) -> QuoteExtractionPipeline {
        if let scenario = UITestConfiguration.mockExtractionScenario {
            return QuoteExtractionPipeline(extractor: UITestQuoteExtractor(scenario: scenario))
        }

        let localExtractor = OnDeviceQuoteExtractor()
        guard AIProcessingConsentStore.shared.hasCurrentConsent else {
            return QuoteExtractionPipeline(
                extractor: localExtractor,
                localOnlyReason: .remoteProcessingDisabled
            )
        }

        return QuoteExtractionPipeline(
            localExtractor: localExtractor,
            remoteExtractor: RemoteModelQuoteExtractor(authService: authService),
            isRemoteProcessingEnabled: true
        )
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        let result = try await extractor.extractQuotes(from: image, markings: markings)
        guard let localOnlyReason else { return result }
        return result.withFallbackReason(localOnlyReason)
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
        let remoteResult: QuoteExtractionResult
        do {
            remoteResult = try await remoteExtractor.extractQuotes(from: image, markings: markings)
        } catch let remoteError {
            return try await localExtractor
                .extractQuotes(from: image, markings: markings)
                .withFallbackReason(.from(remoteError))
        }

        return remoteResult
    }
}
