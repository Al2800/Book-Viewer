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

    func testManualFallbackKeepsCoverImageWhenExtractionCannotReadMetadata() {
        let fallback = CoverMetadataNormalizer.manualFallback(coverImageData: Data([7]))

        XCTAssertEqual(fallback.title, "")
        XCTAssertEqual(fallback.authors, [])
        XCTAssertEqual(fallback.coverImageData, Data([7]))
        XCTAssertEqual(fallback.source, .manual)
    }
}
