import CoreGraphics
import Foundation

struct QuoteMarkTextSelector: Sendable {
    func selectCandidates(
        textLines: [RecognizedTextLine],
        marks: [DetectedPageMark]
    ) -> [OnDeviceQuoteCandidate] {
        let underlineMarks = marks.filter { $0.type == .underline || $0.type == .doubleUnderline }
        let marginLineMarks = marks.filter { $0.type == .marginLine }
        let groupedMarkTypes: Set<MarkingType> = [.underline, .doubleUnderline, .marginLine]
        let nonGroupedMarks = marks.filter { !groupedMarkTypes.contains($0.type) }

        let underlineCandidates = groupedUnderlineCandidates(
            marks: underlineMarks,
            textLines: textLines
        )
        let marginLineCandidates = groupedMarginLineCandidates(
            marks: marginLineMarks,
            textLines: textLines
        )
        let otherCandidates = nonGroupedMarks.compactMap { mark in
            let selectedLines = lines(for: mark, from: textLines)
            return candidate(from: selectedLines, marks: [mark], markingType: mark.type)
        }

        return deduplicatedCandidates(underlineCandidates + marginLineCandidates + otherCandidates)
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

    private func groupedUnderlineCandidates(
        marks: [DetectedPageMark],
        textLines: [RecognizedTextLine]
    ) -> [OnDeviceQuoteCandidate] {
        let selections = marks.compactMap { mark -> MarkedLineSelection? in
            guard let line = closestLineAboveUnderline(mark, textLines: textLines) else {
                return nil
            }
            return MarkedLineSelection(line: line, mark: mark)
        }
        let uniqueSelections = deduplicatedUnderlineSelections(selections)
            .sorted { $0.line.boundingBox.minY < $1.line.boundingBox.minY }

        let groups = groupAdjacentUnderlineSelections(uniqueSelections)
        return groups.compactMap { group in
            candidate(
                from: group.map(\.line),
                marks: group.map(\.mark),
                markingType: .underline
            )
        }
    }

    private func groupedMarginLineCandidates(
        marks: [DetectedPageMark],
        textLines: [RecognizedTextLine]
    ) -> [OnDeviceQuoteCandidate] {
        let selections = marks.flatMap { mark in
            marginMarkedLines(mark, textLines: textLines).map { line in
                MarkedLineSelection(line: line, mark: mark)
            }
        }
        let uniqueSelections = deduplicatedMarkedLineSelections(selections)
            .sorted { $0.line.boundingBox.minY < $1.line.boundingBox.minY }
        let groups = groupAdjacentMarkedLineSelections(uniqueSelections)

        return groups.compactMap { group in
            candidate(
                from: group.map(\.line),
                marks: group.map(\.mark),
                markingType: .marginLine
            )
        }
    }

    private func candidate(
        from selectedLines: [RecognizedTextLine],
        marks: [DetectedPageMark],
        markingType: MarkingType
    ) -> OnDeviceQuoteCandidate? {
        guard !selectedLines.isEmpty else { return nil }

        let text = selectedLines
            .sorted { $0.boundingBox.minY < $1.boundingBox.minY }
            .map(\.text)
            .joined(separator: " ")
            .normalizingWhitespace()

        guard !text.isEmpty else { return nil }

        let averageOCRConfidence = selectedLines.map(\.confidence).reduce(0, +) / Double(selectedLines.count)
        let averageMarkConfidence = marks.isEmpty
            ? 0.55
            : marks.map(\.confidence).reduce(0, +) / Double(marks.count)
        let confidence = min(0.98, max(0.45, (averageOCRConfidence + averageMarkConfidence) / 2))

        return OnDeviceQuoteCandidate(
            text: text,
            markingType: markingType,
            marginNote: nil,
            confidence: confidence
        )
    }

    private func closestLinesAboveUnderline(
        _ mark: DetectedPageMark,
        textLines: [RecognizedTextLine]
    ) -> [RecognizedTextLine] {
        guard let closest = closestLineAboveUnderline(mark, textLines: textLines) else {
            return []
        }

        return [closest]
    }

    private func closestLineAboveUnderline(
        _ mark: DetectedPageMark,
        textLines: [RecognizedTextLine]
    ) -> RecognizedTextLine? {
        let candidates = textLines.filter { line in
            let overlap = horizontalOverlapRatio(line.boundingBox, mark.boundingBox)
            let verticalGap = mark.boundingBox.minY - line.boundingBox.maxY
            let allowedGap = max(80, line.boundingBox.height * 1.8)
            return overlap >= 0.25 && verticalGap >= -line.boundingBox.height && verticalGap <= allowedGap
        }

        return candidates.min(by: {
            abs(mark.boundingBox.minY - $0.boundingBox.maxY) < abs(mark.boundingBox.minY - $1.boundingBox.maxY)
        })
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

    private func deduplicatedUnderlineSelections(_ selections: [MarkedLineSelection]) -> [MarkedLineSelection] {
        deduplicatedMarkedLineSelections(selections)
    }

    private func deduplicatedMarkedLineSelections(_ selections: [MarkedLineSelection]) -> [MarkedLineSelection] {
        selections.reduce(into: []) { unique, selection in
            let alreadySelected = unique.contains { existing in
                existing.line.text == selection.line.text
                    && abs(existing.line.boundingBox.midY - selection.line.boundingBox.midY) <= 3
            }
            if !alreadySelected {
                unique.append(selection)
            }
        }
    }

    private func groupAdjacentUnderlineSelections(_ selections: [MarkedLineSelection]) -> [[MarkedLineSelection]] {
        groupAdjacentMarkedLineSelections(selections)
    }

    private func groupAdjacentMarkedLineSelections(_ selections: [MarkedLineSelection]) -> [[MarkedLineSelection]] {
        selections.reduce(into: []) { groups, selection in
            guard var currentGroup = groups.popLast(),
                  let previous = currentGroup.last?.line else {
                groups.append([selection])
                return
            }

            let line = selection.line
            let verticalGap = line.boundingBox.minY - previous.boundingBox.maxY
            let allowedGap = max(34, previous.boundingBox.height * 1.6)
            let sameTextColumn = horizontalOverlapRatio(previous.boundingBox, line.boundingBox) >= 0.25
                || abs(previous.boundingBox.minX - line.boundingBox.minX) <= 80

            if verticalGap >= -previous.boundingBox.height
                && verticalGap <= allowedGap
                && sameTextColumn {
                currentGroup.append(selection)
                groups.append(currentGroup)
            } else {
                groups.append(currentGroup)
                groups.append([selection])
            }
        }
    }

    private func deduplicatedCandidates(_ candidates: [OnDeviceQuoteCandidate]) -> [OnDeviceQuoteCandidate] {
        candidates.reduce(into: []) { unique, candidate in
            let normalizedText = candidate.text.normalizingWhitespace().lowercased()
            let alreadyIncluded = unique.contains {
                $0.text.normalizingWhitespace().lowercased() == normalizedText
            }
            if !alreadyIncluded {
                unique.append(candidate)
            }
        }
    }
}

private struct MarkedLineSelection {
    let line: RecognizedTextLine
    let mark: DetectedPageMark
}

private extension String {
    func normalizingWhitespace() -> String {
        components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
