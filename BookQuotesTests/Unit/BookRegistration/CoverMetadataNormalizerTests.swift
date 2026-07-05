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

    // MARK: - Catalog Matching

    func testBestCatalogMatchAcceptsSameTitleAndAuthorIgnoringCaseAndPunctuation() {
        let extracted = BookMetadata(
            title: "ATOMIC HABITS",
            authors: ["JAMES CLEAR"],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        let match = CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate])

        XCTAssertEqual(match?.title, "Atomic Habits")
    }

    func testBestCatalogMatchAcceptsSubtitledCatalogTitleByPrefix() {
        let extracted = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "Atomic Habits: An Easy & Proven Way to Build Good Habits",
            authors: ["James Clear"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        XCTAssertNotNil(CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate]))
    }

    func testBestCatalogMatchMatchesAuthorsBySurname() {
        let extracted = BookMetadata(
            title: "The Left Hand of Darkness",
            authors: ["Ursula Le Guin"],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "The Left Hand of Darkness",
            authors: ["Ursula K. Le Guin"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        XCTAssertNotNil(CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate]))
    }

    func testBestCatalogMatchRejectsDifferentAuthor() {
        let extracted = BookMetadata(
            title: "Meditations",
            authors: ["Marcus Aurelius"],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "Meditations",
            authors: ["Someone Else"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        XCTAssertNil(CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate]))
    }

    func testBestCatalogMatchRejectsCandidateWithoutCoverImage() {
        let extracted = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            source: .googleBooks
        )

        XCTAssertNil(CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate]))
    }

    func testBestCatalogMatchAcceptsTitleOnlyWhenExtractionHasNoAuthor() {
        let extracted = BookMetadata(
            title: "Atomic Habits",
            authors: [],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        XCTAssertNotNil(CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate]))
    }

    func testBestCatalogMatchRejectsUnrelatedTitle() {
        let extracted = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            source: .coverPhoto
        )
        let candidate = BookMetadata(
            title: "Deep Work",
            authors: ["James Clear"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        XCTAssertNil(CoverMetadataNormalizer.bestCatalogMatch(for: extracted, in: [candidate]))
    }

    // MARK: - Catalog Enrichment

    func testEnrichedPrefersCatalogFieldsAndStockCoverButKeepsExtractedFallbacks() {
        let photoData = Data([1, 2, 3])
        let stockData = Data([9, 9, 9])
        let extracted = BookMetadata(
            title: "ATOMIC HABITS",
            authors: ["JAMES CLEAR"],
            publisher: "Photo Publisher",
            coverImageData: photoData,
            source: .coverPhoto
        )
        let catalog = BookMetadata(
            title: "Atomic Habits",
            subtitle: "An Easy & Proven Way to Build Good Habits",
            authors: ["James Clear"],
            publishedYear: 2018,
            isbn13: "9780735211292",
            pageCount: 320,
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks,
            googleBooksId: "abc123"
        )

        let enriched = CoverMetadataNormalizer.enriched(
            extracted,
            withCatalog: catalog,
            stockCoverData: stockData
        )

        XCTAssertEqual(enriched.title, "Atomic Habits")
        XCTAssertEqual(enriched.authors, ["James Clear"])
        XCTAssertEqual(enriched.subtitle, "An Easy & Proven Way to Build Good Habits")
        XCTAssertEqual(enriched.publisher, "Photo Publisher")
        XCTAssertEqual(enriched.publishedYear, 2018)
        XCTAssertEqual(enriched.isbn13, "9780735211292")
        XCTAssertEqual(enriched.pageCount, 320)
        XCTAssertEqual(enriched.coverImageData, stockData)
        XCTAssertEqual(enriched.source, .coverPhoto)
        XCTAssertEqual(enriched.googleBooksId, "abc123")
    }

    func testEnrichedKeepsPhotoCoverWhenStockDownloadFailed() {
        let photoData = Data([1, 2, 3])
        let extracted = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            coverImageData: photoData,
            source: .coverPhoto
        )
        let catalog = BookMetadata(
            title: "Atomic Habits",
            authors: ["James Clear"],
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        let enriched = CoverMetadataNormalizer.enriched(
            extracted,
            withCatalog: catalog,
            stockCoverData: nil
        )

        XCTAssertEqual(enriched.coverImageData, photoData)
    }

    // MARK: - Stock Cover URLs

    func testStockCoverURLCandidatesPreferOpenLibraryISBNThenGoogleCovers() {
        let catalog = BookMetadata(
            title: "Atomic Habits",
            isbn13: "9780735211292",
            thumbnailURL: "https://books.google.com/thumb.jpg&edge=curl",
            coverURL: "https://books.google.com/large.jpg",
            source: .googleBooks
        )

        let urls = CoverMetadataNormalizer.stockCoverURLCandidates(for: catalog)

        XCTAssertEqual(urls, [
            "https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg?default=false",
            "https://books.google.com/large.jpg",
            "https://books.google.com/thumb.jpg"
        ])
    }

    func testStockCoverURLCandidatesWithoutISBNFallBackToGoogleOnly() {
        let catalog = BookMetadata(
            title: "Atomic Habits",
            thumbnailURL: "https://books.google.com/thumb.jpg",
            source: .googleBooks
        )

        let urls = CoverMetadataNormalizer.stockCoverURLCandidates(for: catalog)

        XCTAssertEqual(urls, ["https://books.google.com/thumb.jpg"])
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
