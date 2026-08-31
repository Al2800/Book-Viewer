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

    func testLiveScanCoordinatorThrottlesFramesAndConfirmsOnce() throws {
        let coordinator = ISBNLiveScanCoordinator(
            configuration: ISBNScanner.ScanConfiguration(
                frameInterval: 0.1,
                confirmationCount: 2,
                hapticFeedback: false
            )
        )

        let first = try XCTUnwrap(coordinator.beginFrame(now: 1.0))
        XCTAssertNil(coordinator.beginFrame(now: 1.05), "In-flight work should reject overlap")
        coordinator.endFrame(first)
        XCTAssertNil(coordinator.beginFrame(now: 1.08), "The configured frame interval should be enforced")

        XCTAssertFalse(coordinator.confirm("9780735211292", for: first))

        let second = try XCTUnwrap(coordinator.beginFrame(now: 1.11))
        coordinator.endFrame(second)
        XCTAssertTrue(coordinator.confirm("9780735211292", for: second))
        XCTAssertNil(coordinator.beginFrame(now: 1.22), "A confirmed ISBN should latch and stop further Vision work")
        XCTAssertFalse(coordinator.confirm("9780735211292", for: second), "Confirmation should emit only once")
    }

    func testLiveScanCoordinatorResetInvalidatesOldFrame() throws {
        let coordinator = ISBNLiveScanCoordinator(
            configuration: ISBNScanner.ScanConfiguration(
                frameInterval: 0,
                confirmationCount: 1,
                hapticFeedback: false
            )
        )

        let stale = try XCTUnwrap(coordinator.beginFrame(now: 1.0))
        coordinator.reset()

        XCTAssertFalse(coordinator.isCurrent(stale))
        XCTAssertFalse(coordinator.confirm("9780735211292", for: stale))

        let current = try XCTUnwrap(coordinator.beginFrame(now: 1.01))
        coordinator.endFrame(current)
        XCTAssertTrue(coordinator.confirm("9780735211292", for: current))
    }
}
