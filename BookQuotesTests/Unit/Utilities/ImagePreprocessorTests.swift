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
