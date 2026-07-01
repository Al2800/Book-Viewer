import UIKit

struct QuoteCaptureImageProcessor {
    struct Result {
        let image: UIImage
        let qualityResult: ImageQualityAnalyzer.QualityResult?
        let qualityError: Error?
    }

    private let cropToVisibleArea: (UIImage, CGSize) throws -> UIImage
    private let autoCropDocument: (UIImage) async -> UIImage
    private let analyzeQuality: (UIImage) async throws -> ImageQualityAnalyzer.QualityResult

    init(
        cropToVisibleArea: @escaping (UIImage, CGSize) throws -> UIImage = ImagePreprocessor.cropToAspectFillPreview,
        autoCropDocument: @escaping (UIImage) async -> UIImage = ImagePreprocessor.autoCropDocument,
        analyzeQuality: @escaping (UIImage) async throws -> ImageQualityAnalyzer.QualityResult = { image in
            let analyzer = ImageQualityAnalyzer(configuration: .lenient)
            return try await analyzer.analyze(image: image)
        }
    ) {
        self.cropToVisibleArea = cropToVisibleArea
        self.autoCropDocument = autoCropDocument
        self.analyzeQuality = analyzeQuality
    }

    func process(
        _ image: UIImage,
        previewSize: CGSize?,
        framingProfile: CameraFramingProfile
    ) async -> Result {
        var prepared = image

        if framingProfile.captureCropBehavior == .aspectFillVisibleArea,
           let previewSize {
            prepared = (try? cropToVisibleArea(prepared, previewSize)) ?? prepared
        }

        let documentPrepared = await autoCropDocument(prepared)
        do {
            let qualityResult = try await analyzeQuality(documentPrepared)
            return Result(
                image: documentPrepared,
                qualityResult: qualityResult,
                qualityError: nil
            )
        } catch {
            return Result(
                image: documentPrepared,
                qualityResult: nil,
                qualityError: error
            )
        }
    }
}
