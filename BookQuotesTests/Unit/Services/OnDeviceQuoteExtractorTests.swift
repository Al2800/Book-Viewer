import UIKit
import XCTest

@testable import BookQuotes

final class OnDeviceQuoteExtractorTests: XCTestCase {

    func testExtractsUnderlinedTextFromSyntheticPageWithoutNetwork() async throws {
        let image = OnDeviceQuoteExtractorTestImage.underlinedPage()
        let extractor = OnDeviceQuoteExtractor()

        let result = try await extractor.extractQuotes(from: image, markings: [])

        XCTAssertEqual(result.quoteCount, 1)
        let quote = try XCTUnwrap(result.quotes.first)
        XCTAssertTrue(
            quote.text.localizedCaseInsensitiveContains("obstacle is the way"),
            "Expected OCR quote text to contain the underlined passage, got: \(quote.text)"
        )
        XCTAssertEqual(quote.markingType, "underline")
        XCTAssertGreaterThanOrEqual(quote.confidence ?? 0, 0.5)
        XCTAssertEqual(quote.extractionSource, .onDevice)
    }

    func testExtractsGraphiteUnderlinedTextFromSyntheticPageWithoutNetwork() async throws {
        let image = OnDeviceQuoteExtractorTestImage.graphiteUnderlinedPage()
        let marks = try PageMarkDetector().detectMarks(in: image)
        XCTAssertFalse(marks.isEmpty, "Expected graphite underline to be detected before OCR selection")

        let extractor = OnDeviceQuoteExtractor()

        let result = try await extractor.extractQuotes(from: image, markings: [])

        XCTAssertEqual(result.quoteCount, 1)
        let quote = try XCTUnwrap(result.quotes.first)
        XCTAssertTrue(
            quote.text.localizedCaseInsensitiveContains("pleasure of finding things out"),
            "Expected OCR quote text to contain the graphite-underlined passage, got: \(quote.text)"
        )
        XCTAssertEqual(quote.markingType, "underline")
        XCTAssertGreaterThanOrEqual(quote.confidence ?? 0, 0.5)
    }

    func testPlainPrintedTextIsNotTreatedAsMarkedQuote() throws {
        let image = OnDeviceQuoteExtractorTestImage.plainTextPage()
        let marks = try PageMarkDetector().detectMarks(in: image)

        XCTAssertTrue(marks.isEmpty, "Expected plain printed text to have no marks, got: \(marks)")
    }

    func testDetectsGraphiteVerticalMarginLineBesideText() throws {
        let image = OnDeviceQuoteExtractorTestImage.graphiteMarginLinePage()
        let marks = try PageMarkDetector().detectMarks(in: image)

        let marginMarks = marks.filter { $0.type == .marginLine }

        XCTAssertEqual(marginMarks.count, 1, "Expected one vertical margin mark, got: \(marks)")
        XCTAssertLessThanOrEqual(marginMarks[0].boundingBox.width, 24)
        XCTAssertGreaterThanOrEqual(marginMarks[0].boundingBox.height, 120)
    }

    func testSelectorGroupsAdjacentUnderlineFragmentsIntoOneQuote() {
        let lines = [
            RecognizedTextLine(text: "breakneck pace of", confidence: 0.92, boundingBox: CGRect(x: 240, y: 220, width: 250, height: 24)),
            RecognizedTextLine(text: "186,000 miles per", confidence: 0.90, boundingBox: CGRect(x: 240, y: 252, width: 250, height: 24)),
            RecognizedTextLine(text: "second, or 669,600,000", confidence: 0.91, boundingBox: CGRect(x: 240, y: 284, width: 330, height: 24)),
            RecognizedTextLine(text: "miles per hour, in a", confidence: 0.89, boundingBox: CGRect(x: 240, y: 316, width: 290, height: 24)),
            RecognizedTextLine(text: "vacuum, does typically", confidence: 0.88, boundingBox: CGRect(x: 240, y: 348, width: 310, height: 24)),
            RecognizedTextLine(text: "slow down", confidence: 0.88, boundingBox: CGRect(x: 240, y: 380, width: 160, height: 24))
        ]
        let marks = [
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 246, width: 120, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 365, y: 246, width: 120, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 278, width: 240, height: 3), confidence: 0.78),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 310, width: 320, height: 3), confidence: 0.78),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 342, width: 280, height: 3), confidence: 0.76),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 374, width: 300, height: 3), confidence: 0.76),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 406, width: 160, height: 3), confidence: 0.74)
        ]

        let candidates = QuoteMarkTextSelector().selectCandidates(textLines: lines, marks: marks)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(
            candidates.first?.text,
            "breakneck pace of 186,000 miles per second, or 669,600,000 miles per hour, in a vacuum, does typically slow down"
        )
    }

    func testSelectorRepairsObviousLineWrapHyphenationAfterSelection() {
        let lines = [
            RecognizedTextLine(text: "to the unbeliev-", confidence: 0.92, boundingBox: CGRect(x: 240, y: 220, width: 250, height: 24)),
            RecognizedTextLine(text: "ably leisurely pace of", confidence: 0.90, boundingBox: CGRect(x: 240, y: 252, width: 330, height: 24)),
            RecognizedTextLine(text: "well-known physics", confidence: 0.91, boundingBox: CGRect(x: 240, y: 284, width: 270, height: 24))
        ]
        let marks = [
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 246, width: 230, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 278, width: 310, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 310, width: 260, height: 3), confidence: 0.75)
        ]

        let candidates = QuoteMarkTextSelector().selectCandidates(textLines: lines, marks: marks)

        XCTAssertEqual(candidates.first?.text, "to the unbelievably leisurely pace of well-known physics")
    }

    func testSelectorPrefersFullerSameBaselineLineOverOrphanFragment() {
        let lines = [
            RecognizedTextLine(text: "gle particle, which slowed that light beam", confidence: 0.72, boundingBox: CGRect(x: 318, y: 220, width: 450, height: 24)),
            RecognizedTextLine(text: "single particle, which slowed that light beam", confidence: 0.88, boundingBox: CGRect(x: 270, y: 220, width: 500, height: 24)),
            RecognizedTextLine(text: "to the unbelievably leisurely pace", confidence: 0.90, boundingBox: CGRect(x: 270, y: 252, width: 390, height: 24))
        ]
        let marks = [
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 330, y: 246, width: 420, height: 3), confidence: 0.74),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 270, y: 278, width: 380, height: 3), confidence: 0.76)
        ]

        let candidates = QuoteMarkTextSelector().selectCandidates(textLines: lines, marks: marks)

        XCTAssertEqual(
            candidates.first?.text,
            "single particle, which slowed that light beam to the unbelievably leisurely pace"
        )
    }

    func testSelectorSplitsSeparateUnderlineBlocksByParagraphGap() {
        let lines = [
            RecognizedTextLine(text: "First marked idea starts here", confidence: 0.92, boundingBox: CGRect(x: 240, y: 220, width: 360, height: 24)),
            RecognizedTextLine(text: "and continues on this line", confidence: 0.90, boundingBox: CGRect(x: 240, y: 252, width: 330, height: 24)),
            RecognizedTextLine(text: "Second marked idea starts here", confidence: 0.91, boundingBox: CGRect(x: 240, y: 360, width: 380, height: 24)),
            RecognizedTextLine(text: "and has its own underlining", confidence: 0.89, boundingBox: CGRect(x: 240, y: 392, width: 350, height: 24))
        ]
        let marks = [
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 246, width: 340, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 278, width: 320, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 386, width: 360, height: 3), confidence: 0.75),
            DetectedPageMark(type: .underline, boundingBox: CGRect(x: 240, y: 418, width: 340, height: 3), confidence: 0.75)
        ]

        let candidates = QuoteMarkTextSelector().selectCandidates(textLines: lines, marks: marks)

        XCTAssertEqual(candidates.map(\.text), [
            "First marked idea starts here and continues on this line",
            "Second marked idea starts here and has its own underlining"
        ])
    }

    func testSelectorGroupsBrokenMarginLineBesideOneParagraph() {
        let lines = [
            RecognizedTextLine(text: "The marked paragraph begins here", confidence: 0.92, boundingBox: CGRect(x: 260, y: 220, width: 360, height: 24)),
            RecognizedTextLine(text: "and continues with the same idea", confidence: 0.90, boundingBox: CGRect(x: 260, y: 252, width: 360, height: 24)),
            RecognizedTextLine(text: "before ending on this final line", confidence: 0.91, boundingBox: CGRect(x: 260, y: 284, width: 350, height: 24)),
            RecognizedTextLine(text: "Opposite column should not appear", confidence: 0.89, boundingBox: CGRect(x: 760, y: 252, width: 360, height: 24))
        ]
        let marks = [
            DetectedPageMark(type: .marginLine, boundingBox: CGRect(x: 210, y: 218, width: 8, height: 46), confidence: 0.76),
            DetectedPageMark(type: .marginLine, boundingBox: CGRect(x: 211, y: 270, width: 7, height: 42), confidence: 0.74)
        ]

        let candidates = QuoteMarkTextSelector().selectCandidates(textLines: lines, marks: marks)

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(
            candidates.first?.text,
            "The marked paragraph begins here and continues with the same idea before ending on this final line"
        )
        XCTAssertEqual(candidates.first?.markingType, .marginLine)
    }

    func testSelectorSplitsSeparateMarginLinesByParagraphGap() {
        let lines = [
            RecognizedTextLine(text: "First margin quote starts", confidence: 0.92, boundingBox: CGRect(x: 260, y: 220, width: 300, height: 24)),
            RecognizedTextLine(text: "and ends on line two", confidence: 0.90, boundingBox: CGRect(x: 260, y: 252, width: 260, height: 24)),
            RecognizedTextLine(text: "Second margin quote starts", confidence: 0.91, boundingBox: CGRect(x: 260, y: 360, width: 320, height: 24)),
            RecognizedTextLine(text: "and ends separately", confidence: 0.89, boundingBox: CGRect(x: 260, y: 392, width: 250, height: 24))
        ]
        let marks = [
            DetectedPageMark(type: .marginLine, boundingBox: CGRect(x: 210, y: 218, width: 8, height: 62), confidence: 0.76),
            DetectedPageMark(type: .marginLine, boundingBox: CGRect(x: 210, y: 358, width: 8, height: 62), confidence: 0.74)
        ]

        let candidates = QuoteMarkTextSelector().selectCandidates(textLines: lines, marks: marks)

        XCTAssertEqual(candidates.map(\.text), [
            "First margin quote starts and ends on line two",
            "Second margin quote starts and ends separately"
        ])
    }

    @MainActor
    func testRemoteModelQuoteExtractorCallsModelAssistedProxyRoute() async throws {
        let server = HermeticHTTPServer(redactHeaderNames: ["authorization"])
        server.route(method: "POST", path: "/api/extract-quotes-hf") { _ in
            let quoteJSONText =
                #"{"quotes":[{"text":"A model selected marked quote.","markingType":"underline","confidence":0.91}],"processingNotes":"HF model-assisted extraction"}"#
            let responseBody =
                #"{"candidates":[{"content":{"parts":[{"text":\#(String(reflecting: quoteJSONText))}]}}]}"#

            return .json(200, Data(responseBody.utf8))
        }

        try await server.start()
        defer { server.stop() }

        let keychain = KeychainService()
        keychain.setSessionToken("test-session-token")
        let authService = AuthService(keychainService: keychain)
        defer { Task { await authService.signOut() } }

        let extractor = RemoteModelQuoteExtractor(
            authService: authService,
            baseURL: server.baseURL
        )

        let result = try await extractor.extractQuotes(
            from: OnDeviceQuoteExtractorTestImage.plainTextPage(),
            markings: []
        )

        XCTAssertEqual(result.quotes.first?.text, "A model selected marked quote.")
        XCTAssertEqual(result.quotes.first?.markingType, "underline")
        XCTAssertEqual(result.quotes.first?.extractionSource, .modelAssisted)
        XCTAssertEqual(result.processingNotes, "HF model-assisted extraction")

        let request = try XCTUnwrap(server.allRequests().first)
        XCTAssertEqual(request.path, "/api/extract-quotes-hf")
        XCTAssertEqual(request.headers["Authorization"], "<redacted>")

        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: request.body) as? [String: Any])
        XCTAssertNotNil(body["contents"])
    }

    func testModelAssistedExtractorUsesRemoteModelBeforeLocalOCR() async throws {
        let local = SpyQuoteExtractor(result: QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "confident but incomplete local OCR fragment",
                    pageNumber: nil,
                    marginNote: nil,
                    markingType: "underline",
                    confidence: 0.95
                )
            ],
            pageNumber: nil,
            processingNotes: "local OCR"
        ))
        let remote = SpyQuoteExtractor(result: QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "complete model-assisted quote across the bracketed paragraph",
                    pageNumber: nil,
                    marginNote: nil,
                    markingType: "bracket",
                    confidence: 0.91
                )
            ],
            pageNumber: nil,
            processingNotes: "model-assisted"
        ))
        let extractor = ModelAssistedQuoteExtractor(
            localExtractor: local,
            remoteExtractor: remote
        )

        let result = try await extractor.extractQuotes(
            from: OnDeviceQuoteExtractorTestImage.plainTextPage(),
            markings: []
        )

        XCTAssertEqual(result.quotes.first?.text, "complete model-assisted quote across the bracketed paragraph")
        XCTAssertEqual(result.processingNotes, "model-assisted")
        XCTAssertEqual(remote.callCount, 1)
        XCTAssertEqual(local.callCount, 0)
    }

    func testModelAssistedExtractorFallsBackToLocalOCRWhenRemoteModelFails() async throws {
        let local = SpyQuoteExtractor(result: QuoteExtractionResult(
            quotes: [
                ExtractedQuoteData(
                    text: "local OCR fallback quote",
                    pageNumber: nil,
                    marginNote: nil,
                    markingType: "underline",
                    confidence: 0.72
                )
            ],
            pageNumber: nil,
            processingNotes: "local fallback"
        ))
        let remote = SpyQuoteExtractor(error: ExtractionError.networkError(URLError(.timedOut)))
        let extractor = ModelAssistedQuoteExtractor(
            localExtractor: local,
            remoteExtractor: remote
        )

        let result = try await extractor.extractQuotes(
            from: OnDeviceQuoteExtractorTestImage.plainTextPage(),
            markings: []
        )

        XCTAssertEqual(result.quotes.first?.text, "local OCR fallback quote")
        XCTAssertEqual(result.processingNotes, "local fallback")
        XCTAssertEqual(remote.callCount, 1)
        XCTAssertEqual(local.callCount, 1)
    }

    func testOnDeviceExtractorReturnsLowConfidenceMarkedCandidatesForReview() async throws {
        let extractor = OnDeviceQuoteExtractor(
            textRecognizer: StubPageTextRecognizer(lines: [
                RecognizedTextLine(
                    text: "low confidence marked quote",
                    confidence: 0.22,
                    boundingBox: CGRect(x: 240, y: 220, width: 360, height: 24)
                )
            ]),
            markDetector: StubPageMarkDetector(marks: [
                DetectedPageMark(
                    type: .underline,
                    boundingBox: CGRect(x: 240, y: 246, width: 330, height: 3),
                    confidence: 0.20
                )
            ])
        )

        let result = try await extractor.extractQuotes(
            from: OnDeviceQuoteExtractorTestImage.plainTextPage(),
            markings: []
        )

        XCTAssertEqual(result.quotes.count, 1)
        XCTAssertEqual(result.quotes.first?.text, "low confidence marked quote")
        XCTAssertLessThanOrEqual(try XCTUnwrap(result.quotes.first?.confidence), 0.5)
    }

    func testRealBookFixtureExtractsUnderlinedPassageWhenProvided() async throws {
        guard let fixturePath = OnDeviceQuoteExtractorTestImage.realBookFixturePath() else {
            throw XCTSkip("Add the local real page fixture to run real book characterization.")
        }
        guard let image = UIImage(contentsOfFile: fixturePath) else {
            XCTFail("Could not load real book fixture at \(fixturePath)")
            return
        }

        let marks = try PageMarkDetector().detectMarks(in: image)
        XCTAssertFalse(marks.isEmpty, "Expected real page fixture to contain detected marks")

        let result = try await OnDeviceQuoteExtractor().extractQuotes(from: image, markings: [])
        let extractedText = result.quotes.map(\.text).joined(separator: " ")

        XCTAssertFalse(result.quotes.isEmpty, "Expected at least one quote, detected marks: \(marks)")
        XCTAssertTrue(
            extractedText.localizedCaseInsensitiveContains("drop of blood")
                || extractedText.localizedCaseInsensitiveContains("skinned over"),
            "Expected underlined Chatham quote, got: \(extractedText)"
        )
    }
}

private struct StubPageTextRecognizer: PageTextRecognizing {
    let lines: [RecognizedTextLine]

    func recognizeText(in image: UIImage) async throws -> [RecognizedTextLine] {
        lines
    }
}

private struct StubPageMarkDetector: PageMarkDetecting {
    let marks: [DetectedPageMark]

    func detectMarks(in image: UIImage) throws -> [DetectedPageMark] {
        marks
    }
}

private final class SpyQuoteExtractor: QuoteExtracting {
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

private enum OnDeviceQuoteExtractorTestImage {
    static func underlinedPage() -> UIImage {
        page(text: "The obstacle is the way.", underlineColor: .systemRed)
    }

    static func graphiteUnderlinedPage() -> UIImage {
        page(
            text: "The pleasure of finding things out.",
            underlineColor: UIColor(white: 0.28, alpha: 1)
        )
    }

    static func plainTextPage() -> UIImage {
        page(text: "The pleasure of finding things out.", underlineColor: nil)
    }

    static func graphiteMarginLinePage() -> UIImage {
        let size = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let paragraphAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 42, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            let lines = [
                "The marked paragraph begins here",
                "and continues with the same idea",
                "before ending on this final line"
            ]
            for (index, line) in lines.enumerated() {
                line.draw(
                    in: CGRect(x: 300, y: 560 + index * 58, width: 760, height: 54),
                    withAttributes: paragraphAttributes
                )
            }

            let path = UIBezierPath()
            path.move(to: CGPoint(x: 250, y: 552))
            path.addLine(to: CGPoint(x: 250, y: 732))
            UIColor(white: 0.22, alpha: 1).setStroke()
            path.lineWidth = 7
            path.stroke()
        }
    }

    static func realBookFixturePath() -> String? {
        if let fixturePath = ProcessInfo.processInfo.environment["REAL_BOOK_QUOTE_FIXTURE_PATH"] {
            return fixturePath
        }

        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fixture = repoRoot
            .appendingPathComponent("local-fixtures")
            .appendingPathComponent("real-pages")
            .appendingPathComponent("british-are-coming-underlined-page.jpg")
        return FileManager.default.fileExists(atPath: fixture.path) ? fixture.path : nil
    }

    private static func page(text: String, underlineColor: UIColor?) -> UIImage {
        let size = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let paragraphAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 54, weight: .regular),
                .foregroundColor: UIColor.black
            ]
            let textRect = CGRect(x: 140, y: 620, width: 900, height: 80)
            text.draw(in: textRect, withAttributes: paragraphAttributes)

            guard let underlineColor else { return }

            let underlineY = textRect.maxY + 8
            let path = UIBezierPath()
            path.move(to: CGPoint(x: textRect.minX, y: underlineY))
            path.addLine(to: CGPoint(x: textRect.minX + 620, y: underlineY))
            underlineColor.setStroke()
            path.lineWidth = 7
            path.stroke()
        }
    }
}
