import Foundation

struct BookISBNConfirmationDraft {
    var title: String
    var author: String
    var subtitle: String
    var publisher: String
    var pageCount: String
    var status: ReadingStatus
    var metadata: BookMetadata
    var coverImageData: Data?

    func makeBook() -> Book {
        BookEditSaveDraft(
            title: title,
            author: author,
            subtitle: subtitle,
            isbn: metadata.bestISBN ?? "",
            publisher: publisher,
            publishYear: metadata.publishedYear.map(String.init) ?? "",
            genre: "",
            pageCount: pageCount,
            notes: "",
            status: status,
            coverImageData: BookEditCoverImageData(
                thumbnailData: coverImageData,
                fullData: coverImageData
            )
        )
        .makeBook()
    }
}
