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
        let budget = OnDeviceQuoteCandidateBudget.selected(detectedCandidates)

        let quotes = budget.candidates.map { candidate in
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
            processingNotes: budget.overflowed
                ? "On-device extraction kept the \(OnDeviceQuoteCandidateBudget.maximumReviewableCount) highest-confidence markings in page order"
                : "On-device OCR extraction"
        )
    }
}

extension OnDeviceQuoteExtractor: QuoteExtracting {}

enum OnDeviceQuoteCandidateBudget {
    static let maximumReviewableCount = 8

    static func selected(_ candidates: [OnDeviceQuoteCandidate]) -> (
        candidates: [OnDeviceQuoteCandidate],
        overflowed: Bool
    ) {
        guard candidates.count > maximumReviewableCount else {
            return (candidates, false)
        }

        let selectedIndices = Set(
            candidates.enumerated()
                .sorted { lhs, rhs in
                    if lhs.element.confidence == rhs.element.confidence {
                        return lhs.offset < rhs.offset
                    }
                    return lhs.element.confidence > rhs.element.confidence
                }
                .prefix(maximumReviewableCount)
                .map(\.offset)
        )

        // Confidence decides which candidates survive; original sequence decides review order.
        let keptInPageOrder = candidates.enumerated().compactMap { index, candidate in
            selectedIndices.contains(index) ? candidate : nil
        }
        return (keptInPageOrder, true)
    }
}

struct OnDeviceQuoteCandidate: Sendable, Equatable {
    let text: String
    let markingType: MarkingType
    let marginNote: String?
    let confidence: Double
}
