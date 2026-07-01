import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

struct CoverCaptureMetadataSupport {
    let authService: AuthService

    func extractCoverMetadata(from image: UIImage) async -> BookMetadata {
        let coverData = image.jpegData(compressionQuality: 0.85)
        let service = GeminiService(authService: authService)
        let orchestrator = CoverExtractionOrchestrator(
            extractWithGemini: { image in
                try await service.extractCoverMetadata(from: image)
            },
            extractWithOCR: { image, coverImageData in
                await extractCoverMetadataViaOCR(from: image, coverImageData: coverImageData)
            }
        )

        return await orchestrator.extract(from: image, coverImageData: coverData)
    }

    func extractCoverMetadataViaOCR(from image: UIImage, coverImageData: Data?) async -> BookMetadata {
        guard let cgImage = Self.normalizeOrientation(image).cgImage else {
            return BookMetadata(
                title: "",
                authors: [],
                coverImageData: coverImageData,
                source: .manual
            )
        }

        let observations: [VNRecognizedTextObservation] = await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: (request.results as? [VNRecognizedTextObservation]) ?? [])
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.02

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }

        let lines: [(text: String, box: CGRect)] = observations.compactMap { obs in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return (trimmed, obs.boundingBox)
        }
        .sorted { a, b in
            if abs(a.box.midY - b.box.midY) > 0.03 {
                return a.box.midY > b.box.midY
            }
            return a.box.minX < b.box.minX
        }

        let cleaned = lines
            .map { (text: CoverOCRHeuristics.sanitizeLine($0.text), box: $0.box) }
            .filter { !$0.text.isEmpty }

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: cleaned)
        return BookMetadata(
            title: guess.title,
            authors: CoverMetadataNormalizer.splitAuthors(guess.author),
            coverImageData: coverImageData,
            source: .coverPhoto
        )
    }

    func lookupISBN(_ isbn: String) async throws -> BookMetadata {
        let service = ISBNLookupService()
        return try await service.lookup(isbn: isbn)
    }

    /// Attempts to detect and crop the book cover from the captured image.
    /// Falls back to nil so callers can use their existing manual crop path.
    func detectCoverCrop(_ image: UIImage) async -> UIImage? {
        let normalized = Self.normalizeOrientation(image)
        guard let cgImage = normalized.cgImage else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }

                guard let rectangles = request.results as? [VNRectangleObservation],
                      let best = rectangles.max(by: {
                          ($0.boundingBox.width * $0.boundingBox.height) < ($1.boundingBox.width * $1.boundingBox.height)
                      }) else {
                    continuation.resume(returning: nil)
                    return
                }

                let ciImage = CIImage(cgImage: cgImage)
                let size = ciImage.extent.size

                let topLeft = CGPoint(x: best.topLeft.x * size.width, y: best.topLeft.y * size.height)
                let topRight = CGPoint(x: best.topRight.x * size.width, y: best.topRight.y * size.height)
                let bottomLeft = CGPoint(x: best.bottomLeft.x * size.width, y: best.bottomLeft.y * size.height)
                let bottomRight = CGPoint(x: best.bottomRight.x * size.width, y: best.bottomRight.y * size.height)

                let corrected = ciImage.applyingFilter(
                    "CIPerspectiveCorrection",
                    parameters: [
                        "inputTopLeft": CIVector(cgPoint: topLeft),
                        "inputTopRight": CIVector(cgPoint: topRight),
                        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                        "inputBottomRight": CIVector(cgPoint: bottomRight)
                    ]
                )

                let context = CIContext(options: nil)
                guard let output = context.createCGImage(corrected, from: corrected.extent) else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: UIImage(cgImage: output))
            }

            request.maximumObservations = 5
            request.minimumConfidence = 0.6
            request.minimumAspectRatio = 0.45
            request.maximumAspectRatio = 0.9
            request.minimumSize = 0.25
            request.quadratureTolerance = 20

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}
