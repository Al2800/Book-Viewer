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
}
