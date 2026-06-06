import Foundation

// MARK: - Book Edit Source

enum BookEditSource {
    case create
    case edit(Book)
    case metadata(BookMetadata)
}

// MARK: - Book Edit Draft

struct BookEditDraft: Equatable {
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
    var coverImageData: Data?

    init(source: BookEditSource) {
        switch source {
        case .create:
            self.init()

        case .edit(let book):
            self.init(
                title: book.title,
                author: book.author,
                subtitle: book.subtitle ?? "",
                isbn: book.isbn ?? "",
                publisher: book.publisher ?? "",
                publishYear: book.publishYear.map(String.init) ?? "",
                genre: book.genre ?? "",
                pageCount: book.pageCount.map(String.init) ?? "",
                notes: book.notes ?? "",
                status: book.status,
                coverImageData: book.coverFullData ?? book.coverThumbnailData
            )

        case .metadata(let metadata):
            self.init(
                title: metadata.title,
                author: metadata.authorsFormatted,
                subtitle: metadata.subtitle ?? "",
                isbn: metadata.isbn ?? "",
                publisher: metadata.publisher ?? "",
                publishYear: metadata.publishYear.map(String.init) ?? "",
                genre: metadata.genre ?? "",
                pageCount: metadata.pageCount.map(String.init) ?? "",
                notes: "",
                status: .wantToRead,
                coverImageData: metadata.coverImageData
            )
        }
    }

    private init(
        title: String = "",
        author: String = "",
        subtitle: String = "",
        isbn: String = "",
        publisher: String = "",
        publishYear: String = "",
        genre: String = "",
        pageCount: String = "",
        notes: String = "",
        status: ReadingStatus = .wantToRead,
        coverImageData: Data? = nil
    ) {
        self.title = title
        self.author = author
        self.subtitle = subtitle
        self.isbn = isbn
        self.publisher = publisher
        self.publishYear = publishYear
        self.genre = genre
        self.pageCount = pageCount
        self.notes = notes
        self.status = status
        self.coverImageData = coverImageData
    }
}
