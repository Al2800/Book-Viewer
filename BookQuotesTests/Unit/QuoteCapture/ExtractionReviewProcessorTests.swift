import SwiftData
import UIKit
import XCTest

@testable import BookQuotes

@MainActor
final class ExtractionReviewProcessorTests: SwiftDataTestCase {

    func testProcessingPendingCaptureStoresQuotesAndRecordsSessionSuccess() async throws {
        let book = Book(title: "Marked Book", author: "Reader")
        let session = CaptureSession(book: book)
        let capture = PageCapture(imagePath: try writeTestImage())
        session.addCapture(capture)
        session.finishCapturing()
        modelContext.insert(book)
        modelContext.insert(session)
        try modelContext.save()

        let expectedResult = QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "A marked passage selected by the extractor.",
                    pageNumber: 12,
                    marginNote: nil,
                    markingType: "underline",
                    confidence: 0.93
                )
            ],
            pageNumber: 12,
            processingNotes: "test extractor"
        )
        let extractor = StubQuoteExtractor(result: expectedResult)
        let processor = ExtractionReviewProcessor(
            modelContext: modelContext,
            session: session,
            quoteExtractor: extractor
        )

        var refreshCount = 0
        await processor.processPendingCaptures(onCaptureChanged: {
            refreshCount += 1
        })

        XCTAssertEqual(session.status, .completed)
        XCTAssertEqual(session.processedPages, 1)
        XCTAssertEqual(session.failedPages, 0)
        XCTAssertEqual(capture.status, .completed)
        XCTAssertEqual(capture.detectedPageNumber, 12)
        XCTAssertEqual(capture.loadExtractedQuotes().first?.text, "A marked passage selected by the extractor.")
        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(extractor.callCount, 1)
    }

    func testOnDeviceExtractionFlowsIntoAnEditableReviewQuote() async throws {
        let book = Book(title: "Marked Book", author: "Reader")
        let session = CaptureSession(book: book)
        let capture = PageCapture(imagePath: try writeTestImage())
        session.addCapture(capture)
        session.finishCapturing()
        modelContext.insert(book)
        modelContext.insert(session)
        try modelContext.save()

        let onDeviceExtractor = OnDeviceQuoteExtractor(
            textRecognizer: FixturePageTextRecognizer(lines: [
                RecognizedTextLine(
                    text: "An on-device quote reaches review.",
                    confidence: 0.94,
                    boundingBox: CGRect(x: 120, y: 220, width: 560, height: 32)
                ),
                RecognizedTextLine(
                    text: "Check this later.",
                    confidence: 0.88,
                    boundingBox: CGRect(x: 760, y: 224, width: 180, height: 28)
                )
            ]),
            markDetector: FixturePageMarkDetector(marks: [
                DetectedPageMark(
                    type: .underline,
                    boundingBox: CGRect(x: 120, y: 260, width: 540, height: 4),
                    confidence: 0.84
                )
            ])
        )
        let processor = ExtractionReviewProcessor(
            modelContext: modelContext,
            session: session,
            quoteExtractor: onDeviceExtractor
        )

        await processor.processPendingCaptures(onCaptureChanged: {})

        XCTAssertEqual(capture.status, .completed)
        var reviewState = ExtractionReviewQuoteState()
        reviewState.loadCompletedQuotes(from: [ExtractionReviewPageQuoteSnapshot(capture: capture)])
        var editableQuote = try XCTUnwrap(reviewState.quotes(for: capture.id).first)

        XCTAssertEqual(editableQuote.text, "An on-device quote reaches review.")
        XCTAssertNil(editableQuote.marginNote)
        XCTAssertEqual(editableQuote.markingType, "underline")
        XCTAssertEqual(editableQuote.extractionSource, .onDevice)
        XCTAssertFalse(editableQuote.isManual)

        editableQuote.text = "Reader-corrected quote."
        editableQuote.marginNote = "Reader-corrected note."
        XCTAssertEqual(editableQuote.text, "Reader-corrected quote.")
        XCTAssertEqual(editableQuote.marginNote, "Reader-corrected note.")
    }

    func testProcessingFailureMarksCaptureFailedAndRecordsSessionFailure() async throws {
        let book = Book(title: "Marked Book", author: "Reader")
        let session = CaptureSession(book: book)
        let capture = PageCapture(imagePath: try writeTestImage())
        session.addCapture(capture)
        session.finishCapturing()
        modelContext.insert(book)
        modelContext.insert(session)
        try modelContext.save()

        let extractor = StubQuoteExtractor(error: ExtractionError.noQuotesFound)
        let processor = ExtractionReviewProcessor(
            modelContext: modelContext,
            session: session,
            quoteExtractor: extractor
        )

        var refreshCount = 0
        await processor.processPendingCaptures(onCaptureChanged: {
            refreshCount += 1
        })

        XCTAssertEqual(session.status, .partialFailure)
        XCTAssertEqual(session.processedPages, 0)
        XCTAssertEqual(session.failedPages, 1)
        XCTAssertEqual(capture.status, .failed)
        XCTAssertEqual(capture.errorMessage, ExtractionError.noQuotesFound.localizedDescription)
        XCTAssertTrue(capture.loadExtractedQuotes().isEmpty)
        XCTAssertEqual(refreshCount, 1)
        XCTAssertEqual(extractor.callCount, 1)
    }

    private func writeTestImage() throws -> String {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        }

        let relativePath = "captures/tests/\(UUID().uuidString).jpg"
        let url = try documentsDirectory()
            .appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url)
        return relativePath
    }

    private func documentsDirectory() throws -> URL {
        guard let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }
}

private final class StubQuoteExtractor: QuoteExtracting {
    private let result: QuoteExtractionResult?
    private let error: Error?
    private(set) var callCount = 0

    init(result: QuoteExtractionResult) {
        self.result = result
        self.error = nil
    }

    init(error: Error) {
        self.result = nil
        self.error = error
    }

    func extractQuotes(
        from image: UIImage,
        markings: [QuoteExtractionPromptBuilder.MarkingPrompt]
    ) async throws -> QuoteExtractionResult {
        callCount += 1
        if let error {
            throw error
        }
        return try XCTUnwrap(result)
    }
}

private struct FixturePageTextRecognizer: PageTextRecognizing {
    let lines: [RecognizedTextLine]

    func recognizeText(in image: UIImage) async throws -> [RecognizedTextLine] {
        lines
    }
}

private struct FixturePageMarkDetector: PageMarkDetecting {
    let marks: [DetectedPageMark]

    func detectMarks(in image: UIImage) throws -> [DetectedPageMark] {
        marks
    }
}
