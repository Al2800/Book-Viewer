import XCTest

@testable import BookQuotes

final class BookEditDraftTests: XCTestCase {

    func testDraftsLoadCreateEditAndMetadataSources() {
        let createDraft = BookEditDraft(source: .create)

        XCTAssertEqual(createDraft.title, "")
        XCTAssertEqual(createDraft.author, "")
        XCTAssertEqual(createDraft.status, .wantToRead)
        XCTAssertNil(createDraft.coverImageData)

        let book = Book(title: "Deep Work", author: "Cal Newport")
        book.subtitle = "Rules for Focused Success"
        book.isbn = "9781455586691"
        book.publisher = "Grand Central"
        book.publishYear = 2016
        book.genre = "business"
        book.pageCount = 304
        book.notes = "A focused productivity book"
        book.status = .currentlyReading
        book.coverFullData = Data([1, 2, 3])

        let editDraft = BookEditDraft(source: .edit(book))

        XCTAssertEqual(editDraft.title, "Deep Work")
        XCTAssertEqual(editDraft.author, "Cal Newport")
        XCTAssertEqual(editDraft.subtitle, "Rules for Focused Success")
        XCTAssertEqual(editDraft.isbn, "9781455586691")
        XCTAssertEqual(editDraft.publisher, "Grand Central")
        XCTAssertEqual(editDraft.publishYear, "2016")
        XCTAssertEqual(editDraft.genre, "business")
        XCTAssertEqual(editDraft.pageCount, "304")
        XCTAssertEqual(editDraft.notes, "A focused productivity book")
        XCTAssertEqual(editDraft.status, .currentlyReading)
        XCTAssertEqual(editDraft.coverImageData, Data([1, 2, 3]))

        let metadata = BookMetadata(
            title: "The Psychology of Money",
            subtitle: "Timeless lessons",
            authors: ["Morgan Housel"],
            publisher: "Harriman House",
            publishedYear: 2020,
            isbn13: "9780857197689",
            pageCount: 256,
            categories: ["business"],
            coverImageData: Data([9, 8, 7])
        )

        let metadataDraft = BookEditDraft(source: .metadata(metadata))

        XCTAssertEqual(metadataDraft.title, "The Psychology of Money")
        XCTAssertEqual(metadataDraft.author, "Morgan Housel")
        XCTAssertEqual(metadataDraft.subtitle, "Timeless lessons")
        XCTAssertEqual(metadataDraft.isbn, "9780857197689")
        XCTAssertEqual(metadataDraft.publisher, "Harriman House")
        XCTAssertEqual(metadataDraft.publishYear, "2020")
        XCTAssertEqual(metadataDraft.genre, "business")
        XCTAssertEqual(metadataDraft.pageCount, "256")
        XCTAssertEqual(metadataDraft.notes, "")
        XCTAssertEqual(metadataDraft.status, .wantToRead)
        XCTAssertEqual(metadataDraft.coverImageData, Data([9, 8, 7]))
    }

    func testGenreOptionsExposeStableLabels() {
        XCTAssertEqual(BookEditOptions.genreLabel(for: "non-fiction"), "Non-Fiction")
        XCTAssertEqual(BookEditOptions.genreLabel(for: "science-fiction"), "Science Fiction")
        XCTAssertEqual(BookEditOptions.genreLabel(for: ""), "None")
    }
}
