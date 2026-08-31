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
    /// Pixel coordinates in the normalized image, used by local mark geometry.
    let boundingBox: CGRect
    /// Top-left normalized coordinates from Vision, retained for downstream consumers.
    let normalizedBoundingBox: CGRect?

    init(
        text: String,
        confidence: Double,
        boundingBox: CGRect,
        normalizedBoundingBox: CGRect? = nil
    ) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.normalizedBoundingBox = normalizedBoundingBox
    }
}

struct DetectedPageMark: Sendable, Equatable {
    let type: MarkingType
    let boundingBox: CGRect
    let confidence: Double
}

struct OnDeviceQuoteExtractor: Sendable {
    private static let maximumReviewableCandidateCount = 8

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
        let detectedMarks = try markDetector.detectMarks(in: image)
        let enabledFamilies = Set(markings.compactMap(\.localMarkingFamily))
        let marks = detectedMarks.filter { mark in
            guard mark.type != .mixed else { return false }
            return enabledFamilies.isEmpty || enabledFamilies.contains(mark.type)
        }
        let detectedCandidates = selector.selectCandidates(textLines: textLines, marks: marks)
        let candidates = detectedCandidates.count <= Self.maximumReviewableCandidateCount
            ? detectedCandidates
            : []

        let quotes = candidates.map { candidate in
            let customMarking = markings.customMarking(
                forLocalMarkingFamily: candidate.markingType
            )
            return ExtractedQuoteData(
                text: candidate.text,
                pageNumber: nil,
                marginNote: candidate.marginNote,
                markingType: candidate.markingType.rawValue,
                confidence: candidate.confidence,
                extractionSource: .onDevice,
                customMarkingDefinitionID: customMarking?.definitionID,
                customMarkingDisplayName: customMarking?.name
            )
        }

        return QuoteExtractionResult(
            quotes: quotes,
            pageNumber: nil,
            processingNotes: detectedCandidates.count <= Self.maximumReviewableCandidateCount
                ? "On-device OCR extraction"
                : "On-device extraction found too many ambiguous markings"
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
