import UIKit
import Vision

struct VisionPageTextRecognizer: PageTextRecognizing {
    func recognizeText(in image: UIImage) async throws -> [RecognizedTextLine] {
        guard let cgImage = normalizedCGImage(from: image) else {
            throw ExtractionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: ExtractionError.parsingError(error.localizedDescription))
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                let lines = observations.compactMap { observation -> RecognizedTextLine? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return nil }

                    return RecognizedTextLine(
                        text: text,
                        confidence: Double(candidate.confidence),
                        boundingBox: Self.pixelRect(from: observation.boundingBox, imageSize: imageSize)
                    )
                }
                .sorted { lhs, rhs in
                    if abs(lhs.boundingBox.minY - rhs.boundingBox.minY) > 8 {
                        return lhs.boundingBox.minY < rhs.boundingBox.minY
                    }
                    return lhs.boundingBox.minX < rhs.boundingBox.minX
                }

                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en_GB", "en_US"]

            Task.detached(priority: .userInitiated) {
                do {
                    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ExtractionError.parsingError(error.localizedDescription))
                }
            }
        }
    }

    private static func pixelRect(from visionRect: CGRect, imageSize: CGSize) -> CGRect {
        CGRect(
            x: visionRect.minX * imageSize.width,
            y: (1 - visionRect.maxY) * imageSize.height,
            width: visionRect.width * imageSize.width,
            height: visionRect.height * imageSize.height
        )
    }

    private func normalizedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up {
            return image.cgImage
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return normalized.cgImage
    }
}
