import UIKit

protocol QuoteExtracting {
    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt]
    ) async throws -> QuoteExtractionResult
}

protocol PageTextRecognizing: Sendable {
    func recognizeText(in image: UIImage) async throws -> [RecognizedTextLine]
}

protocol PageMarkDetecting: Sendable {
    func detectMarks(in image: UIImage) throws -> [DetectedPageMark]
}

struct RecognizedTextLine: Sendable, Equatable {
    let text: String
    let confidence: Double
    let boundingBox: CGRect
}

struct DetectedPageMark: Sendable, Equatable {
    let type: MarkingType
    let boundingBox: CGRect
    let confidence: Double
}

struct OnDeviceQuoteExtractor: Sendable {
    private let textRecognizer: any PageTextRecognizing
    private let markDetector: any PageMarkDetecting
    private let selector: QuoteMarkTextSelector

    init(
        textRecognizer: any PageTextRecognizing = VisionPageTextRecognizer(),
        markDetector: any PageMarkDetecting = PageMarkDetector(),
        selector: QuoteMarkTextSelector = QuoteMarkTextSelector()
    ) {
        self.textRecognizer = textRecognizer
        self.markDetector = markDetector
        self.selector = selector
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt] = []
    ) async throws -> QuoteExtractionResult {
        let textLines = try await textRecognizer.recognizeText(in: image)
        let marks = try markDetector.detectMarks(in: image)
        let candidates = selector.selectCandidates(textLines: textLines, marks: marks)

        let quotes = candidates.map { candidate in
            ExtractedQuoteData(
                text: candidate.text,
                pageNumber: nil,
                marginNote: candidate.marginNote,
                markingType: candidate.markingType.rawValue,
                confidence: candidate.confidence
            )
        }

        return QuoteExtractionResult(
            quotes: quotes,
            pageNumber: nil,
            processingNotes: "On-device OCR extraction"
        )
    }
}

extension OnDeviceQuoteExtractor: QuoteExtracting {}

struct OnDeviceQuoteCandidate: Sendable, Equatable {
    let text: String
    let markingType: MarkingType
    let marginNote: String?
    let confidence: Double
}
