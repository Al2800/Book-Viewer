import XCTest
import UIKit

@testable import BookQuotes

final class CoverExtractionOrchestratorTests: XCTestCase {

    func testGeminiSuccessWithTitleAndAuthorDoesNotRunOCR() async {
        let orchestrator = CoverExtractionOrchestrator(
            extractWithGemini: { _ in
                BookMetadataResult(
                    title: "Kindred",
                    author: "Octavia Butler",
                    subtitle: nil,
                    publisher: "Beacon",
                    publishYear: 1979,
                    genre: "fiction",
                    isbn: "9780807083697",
                    confidence: 0.9
                )
            },
            extractWithOCR: { _, _ in
                XCTFail("OCR should not run when Gemini returns a title and author")
                return BookMetadata(title: "OCR Title", authors: ["OCR Author"])
            }
        )

        let metadata = await orchestrator.extract(from: UIImage(), coverImageData: Data([1, 2, 3]))

        XCTAssertEqual(metadata.title, "Kindred")
        XCTAssertEqual(metadata.authors, ["Octavia Butler"])
        XCTAssertEqual(metadata.coverImageData, Data([1, 2, 3]))
        XCTAssertEqual(metadata.source, .coverPhoto)
    }

    func testGeminiSuccessWithBlankTitleRunsOCRFallback() async {
        var didRunOCR = false
        let orchestrator = CoverExtractionOrchestrator(
            extractWithGemini: { _ in
                BookMetadataResult(
                    title: " ",
                    author: "Unknown",
                    subtitle: nil,
                    publisher: nil,
                    publishYear: nil,
                    genre: nil,
                    isbn: nil,
                    confidence: 0.2
                )
            },
            extractWithOCR: { _, coverImageData in
                didRunOCR = true
                return BookMetadata(
                    title: "OCR Title",
                    authors: ["OCR Author"],
                    coverImageData: coverImageData,
                    source: .coverPhoto
                )
            }
        )

        let metadata = await orchestrator.extract(from: UIImage(), coverImageData: Data([9]))

        XCTAssertTrue(didRunOCR)
        XCTAssertEqual(metadata.title, "OCR Title")
        XCTAssertEqual(metadata.authors, ["OCR Author"])
        XCTAssertEqual(metadata.coverImageData, Data([9]))
    }

    func testGeminiFailureUsesOCRWhenOCRFindsTitle() async {
        let orchestrator = CoverExtractionOrchestrator(
            extractWithGemini: { _ in
                throw NSError(domain: "Gemini", code: 1)
            },
            extractWithOCR: { _, coverImageData in
                BookMetadata(
                    title: "OCR Found Title",
                    authors: ["OCR Author"],
                    coverImageData: coverImageData,
                    source: .coverPhoto
                )
            }
        )

        let metadata = await orchestrator.extract(from: UIImage(), coverImageData: Data([4]))

        XCTAssertEqual(metadata.title, "OCR Found Title")
        XCTAssertEqual(metadata.authors, ["OCR Author"])
        XCTAssertEqual(metadata.coverImageData, Data([4]))
        XCTAssertEqual(metadata.source, .coverPhoto)
    }

    func testGeminiFailureWithBlankOCRReturnsManualFallback() async {
        let orchestrator = CoverExtractionOrchestrator(
            extractWithGemini: { _ in
                throw NSError(domain: "Gemini", code: 1)
            },
            extractWithOCR: { _, coverImageData in
                BookMetadata(
                    title: "",
                    authors: [],
                    coverImageData: coverImageData,
                    source: .coverPhoto
                )
            }
        )

        let metadata = await orchestrator.extract(from: UIImage(), coverImageData: Data([7]))

        XCTAssertEqual(metadata.title, "")
        XCTAssertEqual(metadata.authors, [])
        XCTAssertEqual(metadata.coverImageData, Data([7]))
        XCTAssertEqual(metadata.source, .manual)
    }
}
