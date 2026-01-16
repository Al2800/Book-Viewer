import XCTest
import UIKit

@testable import BookQuotes

// MARK: - ISBNScannerTests

@MainActor
final class ISBNScannerTests: XCTestCase {

    func testScanImageDataInvalidThrows() async {
        let scanner = ISBNScanner()

        do {
            _ = try await scanner.scanImageData(Data())
            XCTFail("Expected invalid image error")
        } catch let error as ISBNScannerError {
            XCTAssertEqual(error.errorDescription, "Invalid image format")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testScanImageReturnsNilWhenNoBarcode() async throws {
        let scanner = ISBNScanner()
        let imageData = TestFixtures.TestImages.blurryPage
        let image = UIImage(data: imageData) ?? UIImage()

        let result = try await scanner.scanImage(image)
        XCTAssertNil(result)
        XCTAssertNil(scanner.detectedISBN)
        XCTAssertNil(scanner.error)
    }

    func testClearResultResetsState() {
        let scanner = ISBNScanner()
        scanner.clearResult()
        XCTAssertNil(scanner.detectedISBN)
        XCTAssertEqual(scanner.confidence, 0)
        XCTAssertNil(scanner.error)
    }
}
