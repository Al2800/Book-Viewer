import CoreGraphics
import UIKit

struct PageMarkDetector: PageMarkDetecting {
    func detectMarks(in image: UIImage) throws -> [DetectedPageMark] {
        guard let cgImage = image.cgImage else {
            throw ExtractionError.invalidImage
        }

        let bitmap = try MarkBitmap(cgImage: cgImage)
        let coloredRowRuns = bitmap.coloredMarkedRowRuns()
        let neutralRowRuns = bitmap.neutralUnderlineRowRuns()
        let horizontalRuns = coloredRowRuns + neutralRowRuns
        let verticalMarks = mergeColumnRuns(
            bitmap.coloredMarkedColumnRuns() + bitmap.neutralMarkedColumnRuns(),
            imageWidth: bitmap.width,
            horizontalRuns: horizontalRuns
        )
        let bracketMarks = verticalMarks.filter { $0.type == .bracket }
        let coloredRegions = mergeRowRuns(coloredRowRuns)
            .filter { !isBracketHook($0.rect, for: bracketMarks) }
            .compactMap(coloredMark)
        let neutralUnderlineRegions = mergeRowRuns(neutralRowRuns)
            .filter { !isBracketHook($0.rect, for: bracketMarks) }
            .compactMap(neutralUnderlineMark)

        let horizontalMarks = classifyDoubleUnderlines(coloredRegions + neutralUnderlineRegions)
        return horizontalMarks + verticalMarks
    }

    private func coloredMark(_ region: MarkRegion) -> DetectedPageMark? {
        let rect = region.rect
        guard rect.width >= 40, rect.height >= 2 else { return nil }

        return DetectedPageMark(
            type: classify(rect),
            boundingBox: rect,
            confidence: region.confidence
        )
    }

    private func neutralUnderlineMark(_ region: MarkRegion) -> DetectedPageMark? {
        let rect = region.rect
        guard rect.width >= 60 else { return nil }
        guard rect.height >= 1 && rect.height <= 22 else { return nil }
        guard rect.width / max(rect.height, 1) >= 8 else { return nil }
        guard region.density >= 0.2 else { return nil }

        return DetectedPageMark(
            type: .underline,
            boundingBox: rect,
            confidence: min(0.8, max(0.5, region.density))
        )
    }

    private func verticalMarginMark(
        _ region: MarkRegion,
        imageWidth: Int,
        horizontalRuns: [MarkRowRun]
    ) -> DetectedPageMark? {
        let rect = region.rect
        guard rect.height >= 140 else { return nil }
        guard rect.width >= 1 && rect.width <= 24 else { return nil }
        guard rect.height / max(rect.width, 1) >= 5 else { return nil }
        guard region.density >= 0.2 else { return nil }

        let horizontalPosition = rect.midX / CGFloat(max(imageWidth, 1))
        guard horizontalPosition <= 0.35 || horizontalPosition >= 0.65 else { return nil }

        return DetectedPageMark(
            type: hasBracketHook(near: rect, in: horizontalRuns) ? .bracket : .marginLine,
            boundingBox: rect,
            confidence: min(0.82, max(0.55, region.density))
        )
    }

    private func classify(_ rect: CGRect) -> MarkingType {
        if rect.height >= 24 {
            return .highlight
        }

        if rect.width / max(rect.height, 1) >= 6 {
            return .underline
        }

        if rect.height / max(rect.width, 1) >= 3 {
            return .marginLine
        }

        return .mixed
    }

    private func mergeRowRuns(_ runs: [MarkRowRun]) -> [MarkRegion] {
        var regions: [MarkRegion] = []

        for run in runs {
            if let index = regions.lastIndex(where: { $0.canAbsorb(run) }) {
                regions[index].absorb(run)
            } else {
                regions.append(MarkRegion(run: run))
            }
        }

        return regions.filter { $0.rect.width >= 40 }
    }

    private func mergeColumnRuns(
        _ runs: [MarkColumnRun],
        imageWidth: Int,
        horizontalRuns: [MarkRowRun]
    ) -> [DetectedPageMark] {
        var regions: [MarkRegion] = []

        for run in runs.sorted(by: { lhs, rhs in
            lhs.x == rhs.x ? lhs.minY < rhs.minY : lhs.x < rhs.x
        }) {
            if let index = regions.lastIndex(where: { $0.canAbsorb(run) }) {
                regions[index].absorb(run)
            } else {
                regions.append(MarkRegion(run: run))
            }
        }

        return regions.compactMap {
            verticalMarginMark(
                $0,
                imageWidth: imageWidth,
                horizontalRuns: horizontalRuns
            )
        }
    }

    private func hasBracketHook(near verticalRect: CGRect, in runs: [MarkRowRun]) -> Bool {
        runs.contains { run in
            let hookRect = run.rect
            let maximumHookWidth = max(120, verticalRect.width * 16)
            let isHookLength = hookRect.width >= 24 && hookRect.width <= maximumHookWidth
            let touchesVerticalStroke = hookRect.maxX >= verticalRect.minX - 16
                && hookRect.minX <= verticalRect.maxX + 16
            let isNearEndpoint = abs(hookRect.midY - verticalRect.minY) <= 24
                || abs(hookRect.midY - verticalRect.maxY) <= 24
            return isHookLength && touchesVerticalStroke && isNearEndpoint
        }
    }

    private func isBracketHook(_ rect: CGRect, for bracketMarks: [DetectedPageMark]) -> Bool {
        bracketMarks.contains { bracket in
            let maximumHookWidth = max(120, bracket.boundingBox.width * 16)
            let isHookLength = rect.width >= 24 && rect.width <= maximumHookWidth
            let touchesVerticalStroke = rect.maxX >= bracket.boundingBox.minX - 16
                && rect.minX <= bracket.boundingBox.maxX + 16
            let isNearEndpoint = abs(rect.midY - bracket.boundingBox.minY) <= 24
                || abs(rect.midY - bracket.boundingBox.maxY) <= 24
            return isHookLength && touchesVerticalStroke && isNearEndpoint
        }
    }

    private func classifyDoubleUnderlines(_ marks: [DetectedPageMark]) -> [DetectedPageMark] {
        let ordered = marks.enumerated().sorted { lhs, rhs in
            lhs.element.boundingBox.minY == rhs.element.boundingBox.minY
                ? lhs.element.boundingBox.minX < rhs.element.boundingBox.minX
                : lhs.element.boundingBox.minY < rhs.element.boundingBox.minY
        }
        var matchedIndices = Set<Int>()
        var classified: [DetectedPageMark] = []

        for (position, entry) in ordered.enumerated() {
            let index = entry.offset
            let mark = entry.element
            guard !matchedIndices.contains(index) else { continue }
            guard mark.type == .underline else {
                classified.append(mark)
                continue
            }

            if let pair = ordered.dropFirst(position + 1).first(where: { candidate in
                !matchedIndices.contains(candidate.offset)
                    && candidate.element.type == .underline
                    && isDoubleUnderlinePair(mark, candidate.element)
            }) {
                matchedIndices.insert(index)
                matchedIndices.insert(pair.offset)
                classified.append(
                    DetectedPageMark(
                        type: .doubleUnderline,
                        boundingBox: mark.boundingBox.union(pair.element.boundingBox),
                        confidence: (mark.confidence + pair.element.confidence) / 2
                    )
                )
            } else {
                classified.append(mark)
            }
        }

        return classified
    }

    private func isDoubleUnderlinePair(_ first: DetectedPageMark, _ second: DetectedPageMark) -> Bool {
        let verticalGap = second.boundingBox.minY - first.boundingBox.maxY
        guard verticalGap >= 0 else { return false }
        guard verticalGap <= max(48, min(first.boundingBox.height, second.boundingBox.height) * 2.5) else {
            return false
        }

        let overlap = min(first.boundingBox.maxX, second.boundingBox.maxX)
            - max(first.boundingBox.minX, second.boundingBox.minX)
        guard overlap > 0 else { return false }
        return overlap / max(min(first.boundingBox.width, second.boundingBox.width), 1) >= 0.75
    }
}

private struct MarkRowRun {
    let y: Int
    let minX: Int
    let maxX: Int
    let markedPixelCount: Int

    var rect: CGRect {
        CGRect(x: minX, y: y, width: maxX - minX + 1, height: 1)
    }
}

private struct MarkColumnRun {
    let x: Int
    let minY: Int
    let maxY: Int
    let markedPixelCount: Int

    var rect: CGRect {
        CGRect(x: x, y: minY, width: 1, height: maxY - minY + 1)
    }
}

private struct MarkRegion {
    private(set) var rect: CGRect
    private var markedPixelCount: Int
    private var rowCount: Int

    var confidence: Double {
        min(0.95, max(0.55, density))
    }

    var density: Double {
        Double(markedPixelCount) / max(rect.width * rect.height, 1)
    }

    init(run: MarkRowRun) {
        rect = run.rect
        markedPixelCount = run.markedPixelCount
        rowCount = 1
    }

    init(run: MarkColumnRun) {
        rect = run.rect
        markedPixelCount = run.markedPixelCount
        rowCount = 1
    }

    func canAbsorb(_ run: MarkRowRun) -> Bool {
        let closeVertically = CGFloat(run.y) <= rect.maxY + 4
        let overlapsHorizontally = CGFloat(run.maxX) >= rect.minX - 12
            && CGFloat(run.minX) <= rect.maxX + 12
        return closeVertically && overlapsHorizontally
    }

    func canAbsorb(_ run: MarkColumnRun) -> Bool {
        let closeHorizontally = CGFloat(run.x) <= rect.maxX + 4
        let overlapsVertically = CGFloat(run.maxY) >= rect.minY - 12
            && CGFloat(run.minY) <= rect.maxY + 12
        return closeHorizontally && overlapsVertically
    }

    mutating func absorb(_ run: MarkRowRun) {
        rect = rect.union(run.rect)
        markedPixelCount += run.markedPixelCount
        rowCount += 1
    }

    mutating func absorb(_ run: MarkColumnRun) {
        rect = rect.union(run.rect)
        markedPixelCount += run.markedPixelCount
        rowCount += 1
    }
}

private struct MarkBitmap {
    let width: Int
    let height: Int
    let pixels: [UInt8]

    init(cgImage: CGImage) throws {
        width = cgImage.width
        height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)

        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ExtractionError.invalidImage
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        pixels = buffer
    }

    func coloredMarkedRowRuns() -> [MarkRowRun] {
        markedRowRuns(where: isColoredMarkPixel)
    }

    func neutralUnderlineRowRuns() -> [MarkRowRun] {
        markedRowRuns(where: isNeutralDarkMarkPixel)
    }

    func coloredMarkedColumnRuns() -> [MarkColumnRun] {
        markedColumnRuns(where: isColoredMarkPixel)
    }

    func neutralMarkedColumnRuns() -> [MarkColumnRun] {
        markedColumnRuns(where: isNeutralDarkMarkPixel)
    }

    private func markedRowRuns(where isMarked: (Int, Int) -> Bool) -> [MarkRowRun] {
        var runs: [MarkRowRun] = []
        let minimumRunWidth = 24

        for y in 0..<height {
            var runStart: Int?
            var markedCount = 0

            for x in 0..<width {
                if isMarked(x, y) {
                    if runStart == nil {
                        runStart = x
                    }
                    markedCount += 1
                } else if let start = runStart {
                    if x - start >= minimumRunWidth {
                        runs.append(MarkRowRun(y: y, minX: start, maxX: x - 1, markedPixelCount: markedCount))
                    }
                    runStart = nil
                    markedCount = 0
                }
            }

            if let start = runStart, width - start >= minimumRunWidth {
                runs.append(MarkRowRun(y: y, minX: start, maxX: width - 1, markedPixelCount: markedCount))
            }
        }

        return runs
    }

    private func markedColumnRuns(where isMarked: (Int, Int) -> Bool) -> [MarkColumnRun] {
        var runs: [MarkColumnRun] = []
        let minimumRunHeight = 48

        for x in 0..<width {
            var runStart: Int?
            var markedCount = 0

            for y in 0..<height {
                if isMarked(x, y) {
                    if runStart == nil {
                        runStart = y
                    }
                    markedCount += 1
                } else if let start = runStart {
                    if y - start >= minimumRunHeight {
                        runs.append(MarkColumnRun(x: x, minY: start, maxY: y - 1, markedPixelCount: markedCount))
                    }
                    runStart = nil
                    markedCount = 0
                }
            }

            if let start = runStart, height - start >= minimumRunHeight {
                runs.append(MarkColumnRun(x: x, minY: start, maxY: height - 1, markedPixelCount: markedCount))
            }
        }

        return runs
    }

    private func isColoredMarkPixel(x: Int, y: Int) -> Bool {
        let index = (y * width + x) * 4
        let red = Int(pixels[index])
        let green = Int(pixels[index + 1])
        let blue = Int(pixels[index + 2])
        let alpha = Int(pixels[index + 3])

        guard alpha > 80 else { return false }

        let redUnderline = red > 150 && green < 130 && blue < 130
        let yellowHighlight = red > 180 && green > 160 && blue < 140
        let blueOrGreenMargin = (blue > 150 || green > 150) && red < 160

        return redUnderline || yellowHighlight || blueOrGreenMargin
    }

    private func isNeutralDarkMarkPixel(x: Int, y: Int) -> Bool {
        let index = (y * width + x) * 4
        let red = Int(pixels[index])
        let green = Int(pixels[index + 1])
        let blue = Int(pixels[index + 2])
        let alpha = Int(pixels[index + 3])

        guard alpha > 80 else { return false }

        let brightest = max(red, green, blue)
        let darkest = min(red, green, blue)
        let saturation = brightest - darkest

        return brightest < 115 && saturation < 35
    }
}
