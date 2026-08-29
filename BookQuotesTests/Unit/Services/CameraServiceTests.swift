import AVFoundation
import XCTest
import UIKit
import CoreMedia

@testable import BookQuotes

// MARK: - CameraServiceTests

final class CameraServiceTests: XCTestCase {

    func testCameraErrorDescriptions() {
        XCTAssertEqual(CameraError.notAuthorized.errorDescription, "Camera access not authorized")
        XCTAssertEqual(CameraError.cameraUnavailable.errorDescription, "Camera is not available")
        XCTAssertEqual(CameraError.cannotAddInput.errorDescription, "Cannot add camera input")
        XCTAssertEqual(CameraError.cannotAddOutput.errorDescription, "Cannot add photo output")
        XCTAssertEqual(CameraError.imageProcessingFailed.errorDescription, "Failed to process captured image")
        XCTAssertEqual(CameraError.captureInProgress.errorDescription, "A photo is already being captured.")
        XCTAssertEqual(CameraError.captureCancelled.errorDescription, "Camera capture was cancelled.")
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

    func testCaptureLifecycleRejectsOverlapAndOnlyAcceptsMatchingCallback() {
        var lifecycle = CameraCaptureLifecycle()
        let firstCaptureID = UUID()

        XCTAssertTrue(lifecycle.begin(captureID: firstCaptureID, photoSettingsID: 41))
        XCTAssertTrue(lifecycle.isCapturing)
        XCTAssertFalse(lifecycle.begin(captureID: UUID(), photoSettingsID: 42))
        XCTAssertNil(lifecycle.captureID(matchingPhotoSettingsID: 42))
        XCTAssertEqual(lifecycle.captureID(matchingPhotoSettingsID: 41), firstCaptureID)
        XCTAssertFalse(lifecycle.finish(captureID: UUID()))
        XCTAssertTrue(lifecycle.finish(captureID: firstCaptureID))
        XCTAssertFalse(lifecycle.isCapturing)
    }

    func testCaptureLifecycleIgnoresCallbackAfterCancellation() {
        var lifecycle = CameraCaptureLifecycle()

        XCTAssertTrue(lifecycle.begin(captureID: UUID(), photoSettingsID: 99))
        lifecycle.cancel()

        XCTAssertFalse(lifecycle.isCapturing)
        XCTAssertNil(lifecycle.captureID(matchingPhotoSettingsID: 99))
    }

    func testCaptureConfigurationSelectsLargestSupportedPhotoDimensions() throws {
        let selected = try XCTUnwrap(CameraCaptureConfiguration.maximumPhotoDimensions(from: [
            CMVideoDimensions(width: 1920, height: 1080),
            CMVideoDimensions(width: 4032, height: 3024),
            CMVideoDimensions(width: 5712, height: 4284)
        ]))

        XCTAssertEqual(selected.width, 5712)
        XCTAssertEqual(selected.height, 4284)
    }

    func testCaptureConfigurationReturnsNilWithoutSupportedDimensions() {
        XCTAssertNil(CameraCaptureConfiguration.maximumPhotoDimensions(from: []))
    }

    func testCaptureConfigurationUsesPortraitRotationAngle() {
        XCTAssertEqual(CameraCaptureConfiguration.portraitRotationAngle, 90)
    }

    func testPreferredPhotoDimensionsStayWithinMemoryBudget() throws {
        let selected = try XCTUnwrap(CameraCaptureConfiguration.preferredPhotoDimensions(from: [
            CMVideoDimensions(width: 1920, height: 1080),
            CMVideoDimensions(width: 4032, height: 3024),
            CMVideoDimensions(width: 5712, height: 4284)
        ]))

        XCTAssertEqual(selected.width, 4032)
        XCTAssertEqual(selected.height, 3024)
    }

    func testPreferredPhotoDimensionsFallBackToSmallestWhenAllExceedBudget() throws {
        let selected = try XCTUnwrap(CameraCaptureConfiguration.preferredPhotoDimensions(
            from: [
                CMVideoDimensions(width: 5712, height: 4284),
                CMVideoDimensions(width: 8064, height: 6048)
            ],
            maxPixelCount: 1_000_000
        ))

        XCTAssertEqual(selected.width, 5712)
        XCTAssertEqual(selected.height, 4284)
    }

    func testPhotoFlashModeUsesRequestedModeWhenSupported() {
        XCTAssertEqual(
            CameraCaptureConfiguration.photoFlashMode(
                for: .on,
                supported: [.off, .on, .auto]
            ),
            .on
        )
        XCTAssertNil(
            CameraCaptureConfiguration.photoFlashMode(
                for: .on,
                supported: [.off]
            )
        )
    }

    @MainActor
    func testCameraServiceCyclesFlashMode() {
        let service = CameraService()
        XCTAssertEqual(service.flashMode, .auto)
        service.cycleFlashMode()
        XCTAssertEqual(service.flashMode, .on)
        service.cycleFlashMode()
        XCTAssertEqual(service.flashMode, .off)
        service.cleanup()
        XCTAssertEqual(service.flashMode, .auto)
    }
}
