import UIKit

struct CoverExtractionOrchestrator {
    typealias GeminiExtractor = (UIImage) async throws -> BookMetadataResult
    typealias OCRExtractor = (UIImage, Data?) async -> BookMetadata

    let extractWithGemini: GeminiExtractor
    let extractWithOCR: OCRExtractor

    func extract(from image: UIImage, coverImageData: Data?) async -> BookMetadata {
        do {
            let result = try await extractWithGemini(image)
            let titleTrimmed = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let authors = CoverMetadataNormalizer.splitAuthors(result.author)
            let ocrFallback = titleTrimmed.isEmpty || authors.isEmpty
                ? await extractWithOCR(image, coverImageData)
                : nil

            return CoverMetadataNormalizer.metadata(
                from: result,
                coverImageData: coverImageData,
                ocrFallback: ocrFallback
            )
        } catch {
            let ocrFallback = await extractWithOCR(image, coverImageData)
            if !ocrFallback.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ocrFallback
            }

            return CoverMetadataNormalizer.manualFallback(coverImageData: coverImageData)
        }
    }
}
