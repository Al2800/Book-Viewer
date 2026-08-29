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

    func testLiveScanCoordinatorThrottlesFramesAndRequiresConfirmation() {
        let coordinator = ISBNLiveScanCoordinator(
            configuration: ISBNScanner.ScanConfiguration(
                frameInterval: 0.1,
                confirmationCount: 2,
                hapticFeedback: false
            )
        )

        XCTAssertTrue(coordinator.beginFrame(now: 1.0))
        XCTAssertFalse(coordinator.beginFrame(now: 1.05), "In-flight frame should reject overlap")
        coordinator.endFrame()
        XCTAssertFalse(coordinator.beginFrame(now: 1.08), "Interval should skip the next frame")
        XCTAssertTrue(coordinator.beginFrame(now: 1.11))
        coordinator.endFrame()

        XCTAssertFalse(coordinator.confirm("9780735211292"))
        XCTAssertTrue(coordinator.confirm("9780735211292"))
        XCTAssertFalse(coordinator.confirm("9780000000002"), "A new ISBN should reset confirmation")
    }
}
