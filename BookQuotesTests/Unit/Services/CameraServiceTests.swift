import XCTest
import UIKit

@testable import BookQuotes

// MARK: - CameraServiceTests

final class CameraServiceTests: XCTestCase {

    func testCameraErrorDescriptions() {
        XCTAssertEqual(CameraError.notAuthorized.errorDescription, "Camera access not authorized")
        XCTAssertEqual(CameraError.cameraUnavailable.errorDescription, "Camera is not available")
        XCTAssertEqual(CameraError.cannotAddInput.errorDescription, "Cannot add camera input")
        XCTAssertEqual(CameraError.cannotAddOutput.errorDescription, "Cannot add photo output")
        XCTAssertEqual(CameraError.imageProcessingFailed.errorDescription, "Failed to process captured image")
    }

    @MainActor
    func testCompressForUploadReturnsData() {
        let imageData = TestFixtures.TestImages.bookCover
        let image = UIImage(data: imageData) ?? UIImage()
        let compressed = CameraService.compressForUpload(image, maxDimension: 200, quality: 0.7)

        XCTAssertNotNil(compressed)
        XCTAssertFalse(compressed?.isEmpty ?? true)
    }

    @MainActor
    func testPreviewSizeForCroppingPreservesLastValidLayoutSize() {
        let service = CameraService()

        service.updatePreviewSize(CGSize(width: 390, height: 844))
        service.updatePreviewSize(.zero)
        service.updatePreviewSize(CGSize(width: -1, height: 844))

        XCTAssertEqual(
            service.currentPreviewSizeForCropping(),
            CGSize(width: 390, height: 844)
        )
    }
}
