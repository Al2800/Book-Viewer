import Foundation

struct BookEditCoverImageData: Equatable {
    var thumbnailData: Data?
    var fullData: Data?
}

struct BookEditSaveDraft {
    var title: String
    var author: String
    var subtitle: String
    var isbn: String
    var publisher: String
    var publishYear: String
    var genre: String
    var pageCount: String
    var notes: String
    var status: ReadingStatus
    var coverImageData: BookEditCoverImageData?

    var isValidForSave: Bool {
        !normalizedTitle.isEmpty
    }

    var isAuthorBlank: Bool {
        normalizedAuthor.isEmpty
    }

    func makeBook() -> Book {
        let book = Book(
            title: normalizedTitle,
            author: resolvedAuthor,
            subtitle: optional(subtitle),
            publisher: optional(publisher),
            isbn: optional(isbn)
        )
        applyEditableFields(to: book)
        return book
    }

    func apply(to book: Book, modifiedAt: Date = Date()) {
        book.title = normalizedTitle
        book.author = resolvedAuthor
        applyEditableFields(to: book)
        book.dateModified = modifiedAt
    }

    private var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedAuthor: String {
        author.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resolvedAuthor: String {
        normalizedAuthor.isEmpty ? "Unknown" : normalizedAuthor
    }

    private func applyEditableFields(to book: Book) {
        book.subtitle = optional(subtitle)
        book.publisher = optional(publisher)
        book.isbn = optional(isbn)
        book.publishYear = Int(publishYear)
        book.genre = optional(genre)
        book.pageCount = Int(pageCount)
        book.notes = optional(notes)
        book.status = status
        book.coverThumbnailData = coverImageData?.thumbnailData
        book.coverFullData = coverImageData?.fullData
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
