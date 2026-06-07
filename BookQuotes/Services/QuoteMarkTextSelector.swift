import CoreGraphics
import Foundation

struct QuoteMarkTextSelector: Sendable {
    func selectCandidates(
        textLines: [RecognizedTextLine],
        marks: [DetectedPageMark]
    ) -> [OnDeviceQuoteCandidate] {
        marks.compactMap { mark in
            let selectedLines = lines(for: mark, from: textLines)
            guard !selectedLines.isEmpty else { return nil }

            let text = selectedLines
                .sorted { $0.boundingBox.minY < $1.boundingBox.minY }
                .map(\.text)
                .joined(separator: " ")
                .normalizingWhitespace()

            guard !text.isEmpty else { return nil }

            let averageOCRConfidence = selectedLines.map(\.confidence).reduce(0, +) / Double(selectedLines.count)
            let confidence = min(0.98, max(0.45, (averageOCRConfidence + mark.confidence) / 2))

            return OnDeviceQuoteCandidate(
                text: text,
                markingType: mark.type,
                marginNote: nil,
                confidence: confidence
            )
        }
    }

    private func lines(
        for mark: DetectedPageMark,
        from textLines: [RecognizedTextLine]
    ) -> [RecognizedTextLine] {
        switch mark.type {
        case .underline, .doubleUnderline:
            return closestLinesAboveUnderline(mark, textLines: textLines)
        case .highlight:
            return highlightedLines(mark, textLines: textLines)
        case .marginLine:
            return marginMarkedLines(mark, textLines: textLines)
        case .marginNote, .bracket, .mixed:
            return highlightedLines(mark, textLines: textLines)
        }
    }

    private func closestLinesAboveUnderline(
        _ mark: DetectedPageMark,
        textLines: [RecognizedTextLine]
    ) -> [RecognizedTextLine] {
        let candidates = textLines.filter { line in
            let overlap = horizontalOverlapRatio(line.boundingBox, mark.boundingBox)
            let verticalGap = mark.boundingBox.minY - line.boundingBox.maxY
            let allowedGap = max(80, line.boundingBox.height * 1.8)
            return overlap >= 0.25 && verticalGap >= -line.boundingBox.height && verticalGap <= allowedGap
        }

        guard let closest = candidates.min(by: {
            abs(mark.boundingBox.minY - $0.boundingBox.maxY) < abs(mark.boundingBox.minY - $1.boundingBox.maxY)
        }) else {
            return []
        }

        return [closest]
    }

    private func highlightedLines(
        _ mark: DetectedPageMark,
        textLines: [RecognizedTextLine]
    ) -> [RecognizedTextLine] {
        let expandedMark = mark.boundingBox.insetBy(dx: -16, dy: -12)
        return textLines.filter { line in
            expandedMark.intersects(line.boundingBox)
                || horizontalOverlapRatio(line.boundingBox, mark.boundingBox) >= 0.35
                    && abs(line.boundingBox.midY - mark.boundingBox.midY) <= max(40, line.boundingBox.height)
        }
    }

    private func marginMarkedLines(
        _ mark: DetectedPageMark,
        textLines: [RecognizedTextLine]
    ) -> [RecognizedTextLine] {
        textLines.filter { line in
            let verticalOverlap = min(line.boundingBox.maxY, mark.boundingBox.maxY) - max(line.boundingBox.minY, mark.boundingBox.minY)
            let isAdjacent = abs(line.boundingBox.minX - mark.boundingBox.maxX) <= max(80, line.boundingBox.height * 2)
            return verticalOverlap > 0 && isAdjacent
        }
    }

    private func horizontalOverlapRatio(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let overlap = min(lhs.maxX, rhs.maxX) - max(lhs.minX, rhs.minX)
        guard overlap > 0 else { return 0 }
        return overlap / max(min(lhs.width, rhs.width), 1)
    }
}

private extension String {
    func normalizingWhitespace() -> String {
        components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
