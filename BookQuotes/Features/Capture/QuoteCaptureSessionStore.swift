import SwiftData
import UIKit

@MainActor
struct QuoteCaptureSessionStore {
    let modelContext: ModelContext

    func createSession(
        for book: Book,
        image: UIImage,
        seedForUITest: Bool
    ) async throws -> CaptureSession {
        let sessionID = UUID()
        let (imagePath, thumbnailData) = try await prepareImageFiles(
            for: image,
            sessionID: sessionID
        )

        let session = CaptureSession(book: book)
        session.id = sessionID
        modelContext.insert(session)

        let pageCapture = PageCapture(imagePath: imagePath, session: session)
        pageCapture.orderIndex = 0
        pageCapture.thumbnailData = thumbnailData

        modelContext.insert(pageCapture)
        session.addCapture(pageCapture)

        if seedForUITest {
            seedExtractionForUITest(pageCapture: pageCapture, session: session)
        } else {
            session.finishCapturing()
        }

        try modelContext.save()
        return session
    }

    private func prepareImageFiles(
        for image: UIImage,
        sessionID: UUID
    ) async throws -> (imagePath: String, thumbnailData: Data?) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let processed = try ImagePreprocessor.processForQuoteExtraction(image)

                    try PageCapture.ensureDirectory(for: sessionID)
                    let imagePath = PageCapture.generateImagePath(sessionId: sessionID)
                    try PageCapture.saveImage(processed.data, to: imagePath)

                    let thumbnailData = try? ImagePreprocessor.createThumbnail(image)
                    continuation.resume(returning: (imagePath, thumbnailData))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func seedExtractionForUITest(
        pageCapture: PageCapture,
        session: CaptureSession
    ) {
        let quotes = [
            ExtractedQuoteData(
                text: "Test quote extracted for UI testing.",
                pageNumber: 12,
                marginNote: nil,
                markingType: "underline",
                confidence: 0.92
            )
        ]

        pageCapture.storeExtractedQuotes(quotes)
        pageCapture.completeProcessing(
            quoteCount: quotes.count,
            avgConfidence: quotes.compactMap { $0.confidence }.first,
            pageNumber: quotes.first?.pageNumber
        )

        session.status = .processing
        session.recordSuccess()
    }
}
