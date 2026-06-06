import XCTest

@testable import BookQuotes

final class CoverMetadataNormalizerTests: XCTestCase {

    func testNormalizesGeminiCoverResultIntoBookMetadata() {
        let result = BookMetadataResult(
            title: "The Left Hand of Darkness",
            author: "Ursula K. Le Guin and Another Writer",
            subtitle: "A Novel",
            publisher: "Ace",
            publishYear: 1969,
            genre: "science-fiction",
            isbn: "9780441478125",
            confidence: 0.92
        )
        let coverData = Data([1, 2, 3])

        let metadata = CoverMetadataNormalizer.metadata(
            from: result,
            coverImageData: coverData,
            ocrFallback: nil
        )

        XCTAssertEqual(metadata.title, "The Left Hand of Darkness")
        XCTAssertEqual(metadata.authors, ["Ursula K. Le Guin", "Another Writer"])
        XCTAssertEqual(metadata.subtitle, "A Novel")
        XCTAssertEqual(metadata.publisher, "Ace")
        XCTAssertEqual(metadata.publishYear, 1969)
        XCTAssertEqual(metadata.isbn, "9780441478125")
        XCTAssertEqual(metadata.genre, "science-fiction")
        XCTAssertEqual(metadata.categories, ["science-fiction"])
        XCTAssertEqual(metadata.coverImageData, coverData)
        XCTAssertEqual(metadata.source, .coverPhoto)
    }

    func testUsesOCRTitleFallbackWhenGeminiTitleIsBlank() {
        let result = BookMetadataResult(
            title: "   ",
            author: "Unknown",
            subtitle: nil,
            publisher: nil,
            publishYear: nil,
            genre: nil,
            isbn: nil,
            confidence: 0.2
        )
        let ocrFallback = BookMetadata(
            title: "OCR Title",
            authors: ["OCR Author"],
            coverImageData: Data([9]),
            source: .coverPhoto
        )

        let metadata = CoverMetadataNormalizer.metadata(
            from: result,
            coverImageData: Data([1]),
            ocrFallback: ocrFallback
        )

        XCTAssertEqual(metadata.title, "OCR Title")
        XCTAssertEqual(metadata.authors, ["OCR Author"])
        XCTAssertEqual(metadata.coverImageData, Data([9]))
    }

    func testUsesOCRAuthorFallbackWhenGeminiAuthorIsBlank() {
        let result = BookMetadataResult(
            title: "Gemini Title",
            author: " ",
            subtitle: nil,
            publisher: nil,
            publishYear: nil,
            genre: nil,
            isbn: "0306406152",
            confidence: 0.4
        )
        let ocrFallback = BookMetadata(
            title: "OCR Title",
            authors: ["OCR Author"],
            source: .coverPhoto
        )

        let metadata = CoverMetadataNormalizer.metadata(
            from: result,
            coverImageData: Data([4]),
            ocrFallback: ocrFallback
        )

        XCTAssertEqual(metadata.title, "Gemini Title")
        XCTAssertEqual(metadata.authors, ["OCR Author"])
        XCTAssertEqual(metadata.isbn, "0306406152")
        XCTAssertEqual(metadata.coverImageData, Data([4]))
    }

    func testRemovesNoisyMarketingLinesFromGeminiTitle() {
        let result = BookMetadataResult(
            title: "\"A masterpiece\"\nNEW YORK TIMES BESTSELLER\nATOMIC HABITS",
            author: "James Clear",
            subtitle: nil,
            publisher: nil,
            publishYear: nil,
            genre: nil,
            isbn: nil,
            confidence: 0.64
        )

        let metadata = CoverMetadataNormalizer.metadata(
            from: result,
            coverImageData: Data([5]),
            ocrFallback: nil
        )

        XCTAssertEqual(metadata.title, "ATOMIC HABITS")
        XCTAssertEqual(metadata.authors, ["James Clear"])
    }

    func testUsesOCRTitleFallbackWhenGeminiTitleIsOnlyMarketingCopy() {
        let result = BookMetadataResult(
            title: "NEW YORK TIMES BESTSELLER",
            author: "James Clear",
            subtitle: nil,
            publisher: nil,
            publishYear: nil,
            genre: nil,
            isbn: nil,
            confidence: 0.42
        )
        let ocrFallback = BookMetadata(
            title: "ATOMIC HABITS",
            authors: ["James Clear"],
            source: .coverPhoto
        )

        let metadata = CoverMetadataNormalizer.metadata(
            from: result,
            coverImageData: Data([6]),
            ocrFallback: ocrFallback
        )

        XCTAssertEqual(metadata.title, "ATOMIC HABITS")
        XCTAssertEqual(metadata.authors, ["James Clear"])
    }

    func testManualFallbackKeepsCoverImageWhenExtractionCannotReadMetadata() {
        let fallback = CoverMetadataNormalizer.manualFallback(coverImageData: Data([7]))

        XCTAssertEqual(fallback.title, "")
        XCTAssertEqual(fallback.authors, [])
        XCTAssertEqual(fallback.coverImageData, Data([7]))
        XCTAssertEqual(fallback.source, .manual)
    }

    func testOCRTitleGuessIgnoresCommonPraiseAndBestsellerLines() {
        let sourceLines: [(text: String, box: CGRect)] = [
            ("\"A masterpiece\"", CGRect(x: 0.1, y: 0.88, width: 0.8, height: 0.04)),
            ("NEW YORK TIMES BESTSELLER", CGRect(x: 0.1, y: 0.8, width: 0.8, height: 0.04)),
            ("ATOMIC HABITS", CGRect(x: 0.1, y: 0.68, width: 0.8, height: 0.08)),
            ("JAMES CLEAR", CGRect(x: 0.1, y: 0.22, width: 0.8, height: 0.05))
        ]
        let lines = sourceLines.compactMap { line -> (text: String, box: CGRect)? in
            let sanitized = CoverOCRHeuristics.sanitizeLine(line.text)
            guard !sanitized.isEmpty else { return nil }
            return (text: sanitized, box: line.box)
        }

        let guess = CoverOCRHeuristics.guessTitleAndAuthor(from: lines)

        XCTAssertEqual(guess.title, "ATOMIC HABITS")
        XCTAssertEqual(guess.author, "JAMES CLEAR")
    }
}
