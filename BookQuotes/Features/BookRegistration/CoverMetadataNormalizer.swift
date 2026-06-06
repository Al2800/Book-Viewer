import Foundation

struct CoverMetadataNormalizer {

    static func metadata(
        from result: BookMetadataResult,
        coverImageData: Data?,
        ocrFallback: BookMetadata?
    ) -> BookMetadata {
        let title = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
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
            title: result.title,
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
}
