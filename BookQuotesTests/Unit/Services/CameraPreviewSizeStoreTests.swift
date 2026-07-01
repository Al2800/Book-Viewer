import XCTest
import CoreGraphics

@testable import BookQuotes

final class CameraPreviewSizeStoreTests: XCTestCase {

    func testRecordLayoutSizeIgnoresInvalidSizes() {
        var store = CameraPreviewSizeStore()

        store.recordLayoutSize(CGSize(width: 390, height: 844))
        store.recordLayoutSize(.zero)
        store.recordLayoutSize(CGSize(width: -1, height: 844))

        XCTAssertEqual(
            store.currentCroppingSize(previewLayerSize: nil),
            CGSize(width: 390, height: 844)
        )
    }

    func testCurrentCroppingSizePrefersLivePreviewLayerSize() {
        var store = CameraPreviewSizeStore()

        store.recordLayoutSize(CGSize(width: 390, height: 844))

        XCTAssertEqual(
            store.currentCroppingSize(previewLayerSize: CGSize(width: 400, height: 800)),
            CGSize(width: 400, height: 800)
        )
    }

    func testCurrentCroppingSizeFallsBackToLastLayoutSizeWhenLayerSizeIsInvalid() {
        var store = CameraPreviewSizeStore()

        store.recordLayoutSize(CGSize(width: 390, height: 844))

        XCTAssertEqual(
            store.currentCroppingSize(previewLayerSize: .zero),
            CGSize(width: 390, height: 844)
        )
    }

    func testCurrentCroppingSizeReturnsNilUntilAValidSizeExists() {
        let store = CameraPreviewSizeStore()

        XCTAssertNil(store.currentCroppingSize(previewLayerSize: nil))
        XCTAssertNil(store.currentCroppingSize(previewLayerSize: .zero))
    }
}
