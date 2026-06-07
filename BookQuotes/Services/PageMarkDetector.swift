import CoreGraphics
import UIKit

struct PageMarkDetector: PageMarkDetecting {
    func detectMarks(in image: UIImage) throws -> [DetectedPageMark] {
        guard let cgImage = image.cgImage else {
            throw ExtractionError.invalidImage
        }

        let bitmap = try MarkBitmap(cgImage: cgImage)
        let rowRuns = bitmap.markedRowRuns()
        let regions = mergeRowRuns(rowRuns)

        return regions.compactMap { region in
            let rect = region.rect
            guard rect.width >= 40, rect.height >= 2 else { return nil }

            let type = classify(rect)
            return DetectedPageMark(
                type: type,
                boundingBox: rect,
                confidence: region.confidence
            )
        }
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

private struct MarkRegion {
    private(set) var rect: CGRect
    private var markedPixelCount: Int
    private var rowCount: Int

    var confidence: Double {
        min(0.95, max(0.55, Double(markedPixelCount) / max(rect.width * rect.height, 1)))
    }

    init(run: MarkRowRun) {
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

    mutating func absorb(_ run: MarkRowRun) {
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

    func markedRowRuns() -> [MarkRowRun] {
        var runs: [MarkRowRun] = []
        let minimumRunWidth = 24

        for y in 0..<height {
            var runStart: Int?
            var markedCount = 0

            for x in 0..<width {
                if isMarkPixel(x: x, y: y) {
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

    private func isMarkPixel(x: Int, y: Int) -> Bool {
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
}
