import CoreGraphics
import SwiftData
import UIKit

@MainActor
struct BatchCapturePageStore {
    struct AppendResult {
        let capture: PageCapture
        let quality: ImageQualityAnalyzer.QualityResult?
    }

    let modelContext: ModelContext
    private let analyzeQuality: @Sendable (UIImage) async -> ImageQualityAnalyzer.QualityResult?

    init(
        modelContext: ModelContext,
        analyzeQuality: @escaping @Sendable (UIImage) async -> ImageQualityAnalyzer.QualityResult? = { image in
            try? await ImageQualityAnalyzer(configuration: .lenient).analyze(image: image)
        }
    ) {
        self.modelContext = modelContext
        self.analyzeQuality = analyzeQuality
    }

    func appendCapture(
        to session: CaptureSession,
        image: UIImage,
        previewSize: CGSize?,
        cropBehavior: CameraCaptureCropBehavior
    ) async throws -> AppendResult {
        let sessionID = session.id
        let prepared = try await prepareImageFiles(
            image: image,
            sessionID: sessionID,
            previewSize: previewSize,
            cropBehavior: cropBehavior
        )

        let capture = PageCapture(imagePath: prepared.imagePath, session: session)
        capture.thumbnailData = prepared.thumbnailData
        capture.qualityScore = prepared.quality?.overallScore

        session.addCapture(capture)
        modelContext.insert(capture)

        return AppendResult(capture: capture, quality: prepared.quality)
    }

    private nonisolated func prepareImageFiles(
        image: UIImage,
        sessionID: UUID,
        previewSize: CGSize?,
        cropBehavior: CameraCaptureCropBehavior
    ) async throws -> PreparedBatchCapture {
        let analyzeQuality = self.analyzeQuality
        return try await Task.detached(priority: .userInitiated) {
            var working = image
            if cropBehavior == .aspectFillVisibleArea,
               let previewSize {
                working = (try? ImagePreprocessor.cropToAspectFillPreview(
                    working,
                    previewSize: previewSize
                )) ?? working
            }

            working = await ImagePreprocessor.autoCropDocument(working)

            // Analyze the document-cropped image, mirroring the single-capture flow.
            let quality = await analyzeQuality(working)

            let processed = try ImagePreprocessor.process(working, config: .highQuality)
            let thumbnailData = try ImagePreprocessor.createThumbnail(working)

            try PageCapture.ensureDirectory(for: sessionID)
            let imagePath = PageCapture.generateImagePath(sessionId: sessionID)
            try PageCapture.saveImage(processed.data, to: imagePath)

            return PreparedBatchCapture(
                imagePath: imagePath,
                thumbnailData: thumbnailData,
                quality: quality
            )
        }.value
    }
}

private struct PreparedBatchCapture: Sendable {
    let imagePath: String
    let thumbnailData: Data
    let quality: ImageQualityAnalyzer.QualityResult?
}
