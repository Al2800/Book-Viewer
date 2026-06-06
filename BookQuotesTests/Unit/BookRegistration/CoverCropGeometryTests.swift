import XCTest
import UIKit

@testable import BookQuotes

final class CoverCropGeometryTests: XCTestCase {

    func testViewportSizeUsesPortraitCoverAspectAndWidthCap() {
        let viewport = CoverCropGeometry.viewportSize(
            for: CGSize(width: 430, height: 800),
            horizontalInset: 48
        )

        XCTAssertEqual(viewport.width, 340, accuracy: 0.001)
        XCTAssertEqual(viewport.height, 510, accuracy: 0.001)
    }

    func testDisplayedImageSizeFillsPortraitViewport() {
        let displayed = CoverCropGeometry.displayedImageSize(
            imageSize: CGSize(width: 300, height: 200),
            viewport: CGSize(width: 150, height: 300),
            zoomScale: 1
        )

        XCTAssertEqual(displayed.width, 450, accuracy: 0.001)
        XCTAssertEqual(displayed.height, 300, accuracy: 0.001)
    }

    func testOffsetClampsToDisplayedImageOverflow() {
        let clamped = CoverCropGeometry.clampedOffset(
            CGSize(width: 500, height: -500),
            imageSize: CGSize(width: 300, height: 200),
            viewport: CGSize(width: 150, height: 300),
            zoomScale: 1
        )

        XCTAssertEqual(clamped.width, 150, accuracy: 0.001)
        XCTAssertEqual(clamped.height, 0, accuracy: 0.001)
    }

    func testCropRectMapsCenteredZoomedViewportIntoImagePoints() {
        let cropRect = CoverCropGeometry.cropRectInPoints(
            imageSize: CGSize(width: 300, height: 600),
            viewport: CGSize(width: 150, height: 300),
            zoomScale: 2,
            offset: .zero
        )

        XCTAssertEqual(cropRect?.origin.x ?? -1, 75, accuracy: 0.001)
        XCTAssertEqual(cropRect?.origin.y ?? -1, 150, accuracy: 0.001)
        XCTAssertEqual(cropRect?.width ?? -1, 150, accuracy: 0.001)
        XCTAssertEqual(cropRect?.height ?? -1, 300, accuracy: 0.001)
    }

    func testCropLifecycleKeepsCapturedImageUntilDismissConsumesPendingCrop() {
        let captured = UIImage()
        let cropped = UIImage()
        var state = CoverCaptureCropLifecycleState()

        state.presentCapturedImage(captured)
        XCTAssertTrue(state.isReviewPresented)
        XCTAssertTrue(state.capturedImage === captured)

        state.acceptCrop(cropped)
        XCTAssertFalse(state.isReviewPresented)
        XCTAssertTrue(state.capturedImage === captured)
        XCTAssertTrue(state.pendingCroppedCover === cropped)

        let imageToProcess = state.consumePendingCroppedCoverAfterReviewDismiss(isProcessing: false)
        XCTAssertTrue(imageToProcess === cropped)
        XCTAssertNil(state.capturedImage)
        XCTAssertNil(state.pendingCroppedCover)
    }

    func testCropLifecycleDismissWithoutPendingCropClearsCapturedImageWhenIdle() {
        let captured = UIImage()
        var state = CoverCaptureCropLifecycleState()

        state.presentCapturedImage(captured)
        let imageToProcess = state.consumePendingCroppedCoverAfterReviewDismiss(isProcessing: false)

        XCTAssertNil(imageToProcess)
        XCTAssertNil(state.capturedImage)
        XCTAssertNil(state.pendingCroppedCover)
        XCTAssertFalse(state.isReviewPresented)
    }
}
