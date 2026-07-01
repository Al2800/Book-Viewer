import Foundation
import SwiftData
import UIKit

@MainActor
struct ExtractionReviewProcessor {
    private let modelContext: ModelContext
    private let session: CaptureSession
    private let quoteExtractor: any QuoteExtracting

    init(
        modelContext: ModelContext,
        session: CaptureSession,
        quoteExtractor: any QuoteExtracting
    ) {
        self.modelContext = modelContext
        self.session = session
        self.quoteExtractor = quoteExtractor
    }

    func processPendingCaptures(onCaptureChanged: @MainActor () -> Void) async {
        let markingPrompts = loadEnabledMarkingPrompts()

        session.beginProcessing()
        saveContext()

        let pending = session.captures
            .filter { $0.status == .pending }
            .map { PendingCapture(id: $0.id, imageURL: $0.imageURL) }

        for item in pending {
            guard let capture = session.captures.first(where: { $0.id == item.id }) else {
                continue
            }

            capture.beginProcessing()
            saveContext()

            do {
                let image = try await loadImage(from: item.imageURL)
                let result = try await quoteExtractor.extractQuotes(
                    from: image,
                    markings: markingPrompts
                )

                try complete(capture, with: result)
                onCaptureChanged()
            } catch {
                fail(capture, with: error)
                onCaptureChanged()
            }
        }
    }

    private func loadEnabledMarkingPrompts() -> [QuoteExtractionPromptBuilder.MarkingPrompt] {
        let descriptor = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate<MarkingDefinition> { $0.isEnabled }
        )
        let markings = (try? modelContext.fetch(descriptor)) ?? []
        return markings.map { QuoteExtractionPromptBuilder.MarkingPrompt($0) }
    }

    private func complete(_ capture: PageCapture, with result: QuoteExtractionResult) throws {
        try capture.completeExtraction(with: result)
        session.recordSuccess()
        saveContext()
    }

    private func fail(_ capture: PageCapture, with error: Error) {
        capture.failProcessing(error: error.localizedDescription)
        session.recordFailure()
        saveContext()
    }

    private func saveContext() {
        try? modelContext.save()
    }

    private nonisolated func loadImage(from url: URL?) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            guard let url else { throw ExtractionError.invalidImage }
            guard let image = UIImage(contentsOfFile: url.path) else {
                throw ExtractionError.invalidImage
            }
            return image
        }.value
    }
}

private struct PendingCapture {
    let id: UUID
    let imageURL: URL?
}
