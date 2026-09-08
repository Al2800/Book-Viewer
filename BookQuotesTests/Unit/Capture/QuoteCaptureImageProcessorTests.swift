import XCTest
import UIKit

@testable import BookQuotes

final class QuoteCaptureImageProcessorTests: XCTestCase {

    func testQuotePageProcessingNeverAutoCropsAndAnalyzesTheOriginalFrame() async throws {
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
        XCTAssertNil(autoCropInput, "Quote capture must not silently replace the framed page with a detected rectangle")
        XCTAssertTrue(qualityInput === sourceImage)
        XCTAssertTrue(result.image === sourceImage)
        XCTAssertEqual(result.image.pngData(), sourceImage.pngData())
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

    func testQuoteProcessingKeepsOriginalFrameWhenQualityAnalysisFails() async {
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

        XCTAssertTrue(result.image === sourceImage)
        XCTAssertEqual(result.image.pngData(), sourceImage.pngData())
        XCTAssertNil(result.qualityResult)
        XCTAssertNotNil(result.qualityError)
    }

    func testQuoteFramePreservesOrientationAndScaleWithoutPreviewGeometry() async throws {
        let pixels = try XCTUnwrap(makeImage(color: .blue).cgImage)
        let source = UIImage(cgImage: pixels, scale: 2, orientation: .right)
        let processor = QuoteCaptureImageProcessor(
            autoCropDocument: { image in
                XCTFail("Document detection must not alter a quote source")
                return image
            },
            analyzeQuality: { _ in self.makeQualityResult(isAcceptable: true) }
        )

        let result = await processor.process(source, previewSize: nil, framingProfile: .quotePage)
        XCTAssertTrue(result.image === source)
        XCTAssertEqual(result.image.imageOrientation, .right)
        XCTAssertEqual(result.image.scale, 2)
        XCTAssertEqual(result.image.size, source.size)
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
