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
