import CoreGraphics
import SwiftData
import UIKit

@MainActor
struct BatchCapturePageStore {
    let modelContext: ModelContext

    func appendCapture(
        to session: CaptureSession,
        image: UIImage,
        previewSize: CGSize?,
        cropBehavior: CameraCaptureCropBehavior,
        qualityScore: Double?
    ) async throws -> PageCapture {
        let sessionID = session.id
        let prepared = try await prepareImageFiles(
            image: image,
            sessionID: sessionID,
            previewSize: previewSize,
            cropBehavior: cropBehavior,
            qualityScore: qualityScore
        )

        let capture = PageCapture(imagePath: prepared.imagePath, session: session)
        capture.thumbnailData = prepared.thumbnailData
        capture.qualityScore = prepared.qualityScore

        session.addCapture(capture)
        modelContext.insert(capture)

        return capture
    }

    private nonisolated func prepareImageFiles(
        image: UIImage,
        sessionID: UUID,
        previewSize: CGSize?,
        cropBehavior: CameraCaptureCropBehavior,
        qualityScore: Double?
    ) async throws -> PreparedBatchCapture {
        try await Task.detached(priority: .userInitiated) {
            var working = image
            if cropBehavior == .aspectFillVisibleArea,
               let previewSize {
                working = (try? ImagePreprocessor.cropToAspectFillPreview(
                    working,
                    previewSize: previewSize
                )) ?? working
            }

            working = await ImagePreprocessor.autoCropDocument(working)

            let processed = try ImagePreprocessor.process(working, config: .highQuality)
            let thumbnailData = try ImagePreprocessor.createThumbnail(working)

            try PageCapture.ensureDirectory(for: sessionID)
            let imagePath = PageCapture.generateImagePath(sessionId: sessionID)
            try PageCapture.saveImage(processed.data, to: imagePath)

            return PreparedBatchCapture(
                imagePath: imagePath,
                thumbnailData: thumbnailData,
                qualityScore: qualityScore
            )
        }.value
    }
}

private struct PreparedBatchCapture: Sendable {
    let imagePath: String
    let thumbnailData: Data
    let qualityScore: Double?
}
