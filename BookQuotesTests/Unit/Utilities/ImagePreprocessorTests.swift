import XCTest
import UIKit

@testable import BookQuotes

// MARK: - ImagePreprocessorTests

final class ImagePreprocessorTests: XCTestCase {

    func testProcessReturnsCompressedData() throws {
        let imageData = TestFixtures.TestImages.bookCover
        let image = UIImage(data: imageData) ?? UIImage()

        let result = try ImagePreprocessor.process(image)
        XCTAssertFalse(result.data.isEmpty)
        XCTAssertGreaterThan(result.compressionRatio, 0)
        XCTAssertEqual(result.originalSize, image.size)
    }

    func testProcessRespectsMaxDimension() throws {
        let imageData = TestFixtures.TestImages.bookPage
        let image = UIImage(data: imageData) ?? UIImage()
        let config = ImagePreprocessor.Config(maxDimension: 200, compressionQuality: 0.8)

        let result = try ImagePreprocessor.process(image, config: config)
        XCTAssertLessThanOrEqual(result.processedSize.width, 200)
        XCTAssertLessThanOrEqual(result.processedSize.height, 200)
    }

    func testQuoteExtractionProcessingAdaptsAHighEntropyImageToTheUploadBudget() throws {
        let image = makeNoisyImage(width: 2048, height: 1536)
        let initial = try ImagePreprocessor.process(image, config: .highQuality)
        let constrainedBudget = initial.data.count / 2

        let result = try ImagePreprocessor.processForQuoteExtraction(
            image,
            maximumUploadBytes: constrainedBudget
        )

        XCTAssertGreaterThan(initial.data.count, constrainedBudget)
        XCTAssertLessThanOrEqual(result.data.count, constrainedBudget)
        XCTAssertLessThan(result.processedSize.width, initial.processedSize.width)
        XCTAssertLessThan(result.processedSize.height, initial.processedSize.height)
    }

    func testProcessWithContrastEnhancement() throws {
        let imageData = TestFixtures.TestImages.bookCover
        let image = UIImage(data: imageData) ?? UIImage()
        var config = ImagePreprocessor.Config.default
        config.enhanceContrast = true
        config.contrastAmount = 0.2

        let result = try ImagePreprocessor.process(image, config: config)
        XCTAssertTrue(result.contrastEnhanced)
    }

    func testThumbnailCreation() throws {
        let imageData = TestFixtures.TestImages.bookCover
        let image = UIImage(data: imageData) ?? UIImage()

        let thumbnail = try ImagePreprocessor.createThumbnail(image)
        XCTAssertFalse(thumbnail.isEmpty)
    }

    func testUIImagePreprocessedExtension() throws {
        let imageData = TestFixtures.TestImages.bookCover
        let image = UIImage(data: imageData) ?? UIImage()

        let data = try image.preprocessed()
        XCTAssertFalse(data.isEmpty)
    }

    private func makeNoisyImage(width: Int, height: Int) -> UIImage {
        var bytes = Data(count: width * height * 4)
        var state: UInt32 = 0x5EED_1234
        bytes.withUnsafeMutableBytes { rawBuffer in
            guard let pixels = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }

            for offset in stride(from: 0, to: rawBuffer.count, by: 4) {
                state = state &* 1_664_525 &+ 1_013_904_223
                pixels[offset] = UInt8(truncatingIfNeeded: state)
                pixels[offset + 1] = UInt8(truncatingIfNeeded: state >> 8)
                pixels[offset + 2] = UInt8(truncatingIfNeeded: state >> 16)
                pixels[offset + 3] = 255
            }
        }

        let provider = CGDataProvider(data: bytes as CFData)!
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
        return UIImage(cgImage: image)
    }
}

// MARK: - CoverOCRHeuristicsTests

final class CoverOCRHeuristicsTests: XCTestCase {

    func testSanitizeLine_TrimsAndCollapsesAndDropsUIStrings() {
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("  Hello \nWorld  "), "Hello World")
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("Cancel"), "")
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("Confirm Book"), "")
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("Add New Book"), "")
    }

    func testSanitizeLine_DropsDigitHeavyLines() {
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("9780735211292"), "")
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("ISBN 978-0-7352-1129-2"), "")

        // Keep reasonable text lines that include a small number of digits.
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("2nd Edition"), "2nd Edition")
    }

    func testSanitizeLine_StripsLeadingByPrefix() {
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("By James Clear"), "James Clear")
        XCTAssertEqual(CoverOCRHeuristics.sanitizeLine("by Daniel Kahneman"), "Daniel Kahneman")
    }

    func testGuessTitleAndAuthor_PrefersTopForTitleAndBottomForAuthor() {
        let lines: [(text: String, box: CGRect)] = [
            ("Atomic Habits", CGRect(x: 0.1, y: 0.75, width: 0.8, height: 0.1)),
            ("Tiny Changes, Remarkable Results", CGRect(x: 0.1, y: 0.62, width: 0.8, height: 0.08)),
            ("James Clear", CGRect(x: 0.1, y: 0.20, width: 0.6, height: 0.06))
        ]

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: lines)
        XCTAssertEqual(guess.title, "Atomic Habits Tiny Changes, Remarkable Results")
        XCTAssertEqual(guess.author, "James Clear")
    }

    func testGuessTitleAndAuthor_ExtractsEmbeddedByAuthor() {
        let lines: [(text: String, box: CGRect)] = [
            ("Thinking, Fast and Slow", CGRect(x: 0.1, y: 0.74, width: 0.8, height: 0.1)),
            ("A classic by Daniel Kahneman", CGRect(x: 0.1, y: 0.40, width: 0.8, height: 0.08))
        ]

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: lines)
        XCTAssertEqual(guess.title, "Thinking, Fast and Slow")
        XCTAssertEqual(guess.author, "Daniel Kahneman")
    }

    func testGuessTitleAndAuthor_PrefersLowestBottomCandidateForAuthor() {
        let lines: [(text: String, box: CGRect)] = [
            ("Atomic Habits", CGRect(x: 0.1, y: 0.78, width: 0.8, height: 0.1)),
            // Subtitle can land in the bottom region depending on OCR box placement.
            ("Tiny Changes, Remarkable Results", CGRect(x: 0.1, y: 0.44, width: 0.8, height: 0.08)),
            ("James Clear", CGRect(x: 0.1, y: 0.20, width: 0.6, height: 0.06))
        ]

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: lines)
        XCTAssertEqual(guess.author, "James Clear")
    }
}
