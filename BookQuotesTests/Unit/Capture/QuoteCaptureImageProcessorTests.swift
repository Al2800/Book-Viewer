import XCTest
import UIKit

@testable import BookQuotes

final class QuoteCaptureImageProcessorTests: XCTestCase {

    func testQuotePageProcessingKeepsFullFrameBeforeDocumentPreparationAndAnalysis() async throws {
        let sourceImage = makeImage(color: .white)
        let documentPreparedImage = makeImage(color: .green)
        let expectedQuality = makeQualityResult(isAcceptable: true)
        var cropCallCount = 0
        var autoCropInput: UIImage?
        var qualityInput: UIImage?

        let processor = QuoteCaptureImageProcessor(
            cropToVisibleArea: { image, _ in
                cropCallCount += 1
                return image
            },
            autoCropDocument: { image in
                autoCropInput = image
                return documentPreparedImage
            },
            analyzeQuality: { image in
                qualityInput = image
                return expectedQuality
            }
        )

        let result = await processor.process(
            sourceImage,
            previewSize: CGSize(width: 390, height: 844),
            framingProfile: .quotePage
        )

        XCTAssertEqual(cropCallCount, 0)
        XCTAssertTrue(autoCropInput === sourceImage)
        XCTAssertTrue(qualityInput === documentPreparedImage)
        XCTAssertTrue(result.image === documentPreparedImage)
        XCTAssertEqual(result.qualityResult?.overallScore, expectedQuality.overallScore)
        XCTAssertNil(result.qualityError)
    }

    func testAspectFillProcessingCropsVisibleAreaBeforeDocumentPreparationAndAnalysis() async throws {
        let sourceImage = makeImage(color: .white)
        let visibleAreaImage = makeImage(color: .blue)
        let documentPreparedImage = makeImage(color: .green)
        let expectedQuality = makeQualityResult(isAcceptable: false)
        var cropPreviewSize: CGSize?
        var autoCropInput: UIImage?
        var qualityInput: UIImage?

        let processor = QuoteCaptureImageProcessor(
            cropToVisibleArea: { _, previewSize in
                cropPreviewSize = previewSize
                return visibleAreaImage
            },
            autoCropDocument: { image in
                autoCropInput = image
                return documentPreparedImage
            },
            analyzeQuality: { image in
                qualityInput = image
                return expectedQuality
            }
        )

        let previewSize = CGSize(width: 300, height: 600)
        let result = await processor.process(
            sourceImage,
            previewSize: previewSize,
            framingProfile: .cover
        )

        XCTAssertEqual(cropPreviewSize, previewSize)
        XCTAssertTrue(autoCropInput === visibleAreaImage)
        XCTAssertTrue(qualityInput === documentPreparedImage)
        XCTAssertTrue(result.image === documentPreparedImage)
        XCTAssertFalse(result.qualityResult?.isAcceptable ?? true)
        XCTAssertNil(result.qualityError)
    }

    func testAspectFillProcessingSkipsVisibleAreaCropWhenPreviewSizeIsMissing() async throws {
        let sourceImage = makeImage(color: .white)
        let documentPreparedImage = makeImage(color: .green)
        var cropCallCount = 0
        var autoCropInput: UIImage?

        let processor = QuoteCaptureImageProcessor(
            cropToVisibleArea: { image, _ in
                cropCallCount += 1
                return image
            },
            autoCropDocument: { image in
                autoCropInput = image
                return documentPreparedImage
            },
            analyzeQuality: { _ in self.makeQualityResult(isAcceptable: true) }
        )

        _ = await processor.process(
            sourceImage,
            previewSize: nil,
            framingProfile: .cover
        )

        XCTAssertEqual(cropCallCount, 0)
        XCTAssertTrue(autoCropInput === sourceImage)
    }

    func testProcessingKeepsPreparedImageWhenQualityAnalysisFails() async {
        struct ExpectedQualityFailure: Error {}

        let sourceImage = makeImage(color: .white)
        let documentPreparedImage = makeImage(color: .green)

        let processor = QuoteCaptureImageProcessor(
            autoCropDocument: { _ in documentPreparedImage },
            analyzeQuality: { _ in throw ExpectedQualityFailure() }
        )

        let result = await processor.process(
            sourceImage,
            previewSize: nil,
            framingProfile: .quotePage
        )

        XCTAssertTrue(result.image === documentPreparedImage)
        XCTAssertNil(result.qualityResult)
        XCTAssertNotNil(result.qualityError)
    }

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }

    private func makeQualityResult(isAcceptable: Bool) -> ImageQualityAnalyzer.QualityResult {
        ImageQualityAnalyzer.QualityResult(
            overallScore: isAcceptable ? 0.9 : 0.3,
            blurScore: isAcceptable ? 150 : 40,
            brightnessScore: 0.5,
            textConfidence: isAcceptable ? 0.8 : 0.2,
            textRegionCount: isAcceptable ? 3 : 0,
            issues: isAcceptable ? [] : [.noTextDetected(advice: "Ensure the book page is visible in frame")],
            isAcceptable: isAcceptable
        )
    }
}
