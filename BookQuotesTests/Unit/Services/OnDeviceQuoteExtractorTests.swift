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
