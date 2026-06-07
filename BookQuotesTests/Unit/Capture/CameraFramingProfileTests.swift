import AVFoundation
import XCTest

@testable import BookQuotes

final class CameraFramingProfileTests: XCTestCase {

    func testQuotePageFramingShowsFullFrameAndDoesNotCropToPreview() {
        let profile = CameraFramingProfile.quotePage

        XCTAssertEqual(profile.previewVideoGravity, .resizeAspect)
        XCTAssertEqual(profile.captureCropBehavior, .none)
        XCTAssertTrue(profile.guidanceText.lowercased().contains("full marked passage"))
        XCTAssertTrue(profile.guidanceText.lowercased().contains("margin marks"))
    }

    func testCoverFramingKeepsAspectFillCropForCoverReview() {
        let profile = CameraFramingProfile.cover

        XCTAssertEqual(profile.previewVideoGravity, .resizeAspectFill)
        XCTAssertEqual(profile.captureCropBehavior, .aspectFillVisibleArea)
        XCTAssertTrue(profile.guidanceText.lowercased().contains("cover"))
    }

    func testAspectFillCropRectMatchesPreviewRatioWithoutEscapingImageBounds() {
        let cropRect = CameraFramingGeometry.aspectFillVisibleRect(
            imageSize: CGSize(width: 4000, height: 3000),
            previewSize: CGSize(width: 390, height: 844)
        )

        XCTAssertEqual(cropRect.origin.x, 1307, accuracy: 1)
        XCTAssertEqual(cropRect.origin.y, 0, accuracy: 1)
        XCTAssertEqual(cropRect.width, 1388, accuracy: 1)
        XCTAssertEqual(cropRect.height, 3000, accuracy: 1)
    }
}
