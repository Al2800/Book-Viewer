import Foundation

struct CoverMetadataNormalizer {

    static func metadata(
        from result: BookMetadataResult,
        coverImageData: Data?,
        ocrFallback: BookMetadata?
    ) -> BookMetadata {
        let title = normalizedTitle(result.title, ocrFallback: ocrFallback)
        var authors = splitAuthors(result.author)

        if title.isEmpty,
           let ocrFallback,
           !ocrFallback.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ocrFallback
        }

        if authors.isEmpty, let ocrFallback, !ocrFallback.authors.isEmpty {
            authors = ocrFallback.authors
        }

        let isbnValue = result.isbn?.trimmingCharacters(in: .whitespacesAndNewlines)
        let isbn10 = isbnValue?.count == 10 ? isbnValue : nil
        let isbn13 = isbnValue?.count == 13 ? isbnValue : nil
        let categories = result.genre.map { [$0] } ?? []

        return BookMetadata(
            title: title,
            subtitle: result.subtitle,
            authors: authors,
            publisher: result.publisher,
            publishedYear: result.publishYear,
            isbn10: isbn10,
            isbn13: isbn13,
            categories: categories,
            coverImageData: coverImageData,
            source: .coverPhoto
        )
    }

    static func manualFallback(coverImageData: Data?) -> BookMetadata {
        BookMetadata(
            title: "",
            authors: [],
            coverImageData: coverImageData,
            source: .manual
        )
    }

    // MARK: - Catalog Enrichment

    /// Pick the catalog result that plausibly matches the photographed cover.
    /// Requires a title match, an author match when both sides know the author,
    /// and a cover image URL (the whole point is swapping in a stock cover).
    static func bestCatalogMatch(
        for extracted: BookMetadata,
        in candidates: [BookMetadata]
    ) -> BookMetadata? {
        let targetTitle = fold(extracted.title)
        guard !targetTitle.isEmpty else { return nil }
        let targetAuthors = extracted.authors.map(fold).filter { !$0.isEmpty }

        return candidates.first { candidate in
            guard candidate.coverImageURL != nil else { return false }

            let candidateTitle = fold(candidate.title)
            guard !candidateTitle.isEmpty else { return false }
            let titleMatches = candidateTitle == targetTitle
                || candidateTitle.hasPrefix(targetTitle)
                || targetTitle.hasPrefix(candidateTitle)
            guard titleMatches else { return false }

            // Title alone is enough when either side lacks author info.
            let candidateAuthors = candidate.authors.map(fold).filter { !$0.isEmpty }
            guard !targetAuthors.isEmpty, !candidateAuthors.isEmpty else { return true }

            return candidateAuthors.contains { candidateAuthor in
                targetAuthors.contains { targetAuthor in
                    authorsMatch(candidateAuthor, targetAuthor)
                }
            }
        }
    }

    /// Merge catalog metadata into the photo-extracted metadata.
    /// Catalog values win for canonical fields (title casing, authors, ISBN);
    /// extracted values remain as fallbacks. The stock cover replaces the
    /// user's skewed photo when one was downloaded.
    static func enriched(
        _ extracted: BookMetadata,
        withCatalog catalog: BookMetadata,
        stockCoverData: Data?
    ) -> BookMetadata {
        let catalogTitle = catalog.title.trimmingCharacters(in: .whitespacesAndNewlines)

        return BookMetadata(
            title: catalogTitle.isEmpty ? extracted.title : catalogTitle,
            subtitle: catalog.subtitle ?? extracted.subtitle,
            authors: catalog.authors.isEmpty ? extracted.authors : catalog.authors,
            publisher: catalog.publisher ?? extracted.publisher,
            publishedYear: catalog.publishedYear ?? extracted.publishedYear,
            publishedDate: catalog.publishedDate ?? extracted.publishedDate,
            isbn10: catalog.isbn10 ?? extracted.isbn10,
            isbn13: catalog.isbn13 ?? extracted.isbn13,
            pageCount: catalog.pageCount ?? extracted.pageCount,
            description: catalog.description ?? extracted.description,
            categories: catalog.categories.isEmpty ? extracted.categories : catalog.categories,
            language: catalog.language ?? extracted.language,
            thumbnailURL: catalog.thumbnailURL ?? extracted.thumbnailURL,
            coverURL: catalog.coverURL ?? extracted.coverURL,
            coverImageData: stockCoverData ?? extracted.coverImageData,
            averageRating: catalog.averageRating ?? extracted.averageRating,
            ratingsCount: catalog.ratingsCount ?? extracted.ratingsCount,
            source: .coverPhoto,
            googleBooksId: catalog.googleBooksId ?? extracted.googleBooksId,
            openLibraryKey: catalog.openLibraryKey ?? extracted.openLibraryKey
        )
    }

    /// Cover image URLs to try for a catalog match, best quality first.
    /// Open Library serves large covers by ISBN (`default=false` makes
    /// missing covers 404 instead of returning a placeholder pixel).
    static func stockCoverURLCandidates(for catalog: BookMetadata) -> [String] {
        var urls: [String] = []

        if let isbn = catalog.bestISBN, !isbn.isEmpty {
            urls.append("https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg?default=false")
        }
        if let coverURL = catalog.coverURL {
            urls.append(sanitizedGoogleCoverURL(coverURL))
        }
        if let thumbnailURL = catalog.thumbnailURL, thumbnailURL != catalog.coverURL {
            urls.append(sanitizedGoogleCoverURL(thumbnailURL))
        }

        return urls
    }

    /// Strip the decorative page-curl effect Google Books adds to some covers.
    private static func sanitizedGoogleCoverURL(_ url: String) -> String {
        url
            .replacingOccurrences(of: "&edge=curl", with: "")
            .replacingOccurrences(of: "edge=curl&", with: "")
    }

    /// Case-, diacritic-, and punctuation-insensitive comparison key.
    private static func fold(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Authors match on equality, containment ("Ursula K. Le Guin" vs
    /// "Ursula Le Guin" fails containment but shares the surname), or surname.
    private static func authorsMatch(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == rhs || lhs.contains(rhs) || rhs.contains(lhs) {
            return true
        }

        let lhsSurname = lhs.split(separator: " ").last
        let rhsSurname = rhs.split(separator: " ").last
        if let lhsSurname, let rhsSurname, lhsSurname == rhsSurname {
            return true
        }

        return false
    }

    static func splitAuthors(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if trimmed.contains("&") {
            return trimmed
                .split(separator: "&")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        if trimmed.localizedCaseInsensitiveContains(" and ") {
            return trimmed
                .components(separatedBy: " and ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        if trimmed.contains(",") {
            return trimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        return [trimmed]
    }

    private static func normalizedTitle(_ raw: String, ocrFallback: BookMetadata?) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let sanitizedLines = trimmed
            .components(separatedBy: .newlines)
            .map(CoverOCRHeuristics.sanitizeLine)
            .filter { !$0.isEmpty }

        let cleaned = sanitizedLines
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleaned.isEmpty {
            return cleaned
        }

        if CoverOCRHeuristics.isMarketingLine(trimmed),
           let fallbackTitle = ocrFallback?.title.trimmingCharacters(in: .whitespacesAndNewlines),
           !fallbackTitle.isEmpty {
            return fallbackTitle
        }

        return trimmed
    }
}
