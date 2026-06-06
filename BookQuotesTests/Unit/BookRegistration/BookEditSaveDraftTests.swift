import XCTest

@testable import BookQuotes

final class BookEditSaveDraftTests: XCTestCase {

    func testCreatesBookFromFormValuesWithNormalization() {
        let draft = BookEditSaveDraft(
            title: "  The Creative Act  ",
            author: "  Rick Rubin  ",
            subtitle: "",
            isbn: "9780593652886",
            publisher: "Penguin Press",
            publishYear: "2023",
            genre: "non-fiction",
            pageCount: "432",
            notes: "",
            status: .currentlyReading,
            coverImageData: BookEditCoverImageData(
                thumbnailData: Data([1, 2, 3]),
                fullData: Data([4, 5, 6])
            )
        )

        let book = draft.makeBook()

        XCTAssertEqual(book.title, "The Creative Act")
        XCTAssertEqual(book.author, "Rick Rubin")
        XCTAssertNil(book.subtitle)
        XCTAssertEqual(book.isbn, "9780593652886")
        XCTAssertEqual(book.publisher, "Penguin Press")
        XCTAssertEqual(book.publishYear, 2023)
        XCTAssertEqual(book.genre, "non-fiction")
        XCTAssertEqual(book.pageCount, 432)
        XCTAssertNil(book.notes)
        XCTAssertEqual(book.status, .currentlyReading)
        XCTAssertEqual(book.coverThumbnailData, Data([1, 2, 3]))
        XCTAssertEqual(book.coverFullData, Data([4, 5, 6]))
    }

    func testBlankAuthorFallsBackToUnknownAndEditClearsOptionalValues() {
        let book = Book(title: "Old Title", author: "Old Author")
        book.subtitle = "Old Subtitle"
        book.publisher = "Old Publisher"
        book.isbn = "old-isbn"
        book.publishYear = 1999
        book.genre = "history"
        book.pageCount = 100
        book.notes = "Old notes"
        book.status = .finished
        book.coverThumbnailData = Data([1])
        book.coverFullData = Data([2])

        let modifiedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let draft = BookEditSaveDraft(
            title: "  New Title  ",
            author: "   ",
            subtitle: "",
            isbn: "",
            publisher: "",
            publishYear: "",
            genre: "",
            pageCount: "",
            notes: "",
            status: .wantToRead,
            coverImageData: nil
        )

        draft.apply(to: book, modifiedAt: modifiedAt)

        XCTAssertEqual(book.title, "New Title")
        XCTAssertEqual(book.author, "Unknown")
        XCTAssertNil(book.subtitle)
        XCTAssertNil(book.publisher)
        XCTAssertNil(book.isbn)
        XCTAssertNil(book.publishYear)
        XCTAssertNil(book.genre)
        XCTAssertNil(book.pageCount)
        XCTAssertNil(book.notes)
        XCTAssertEqual(book.status, .wantToRead)
        XCTAssertEqual(book.dateModified, modifiedAt)
        XCTAssertNil(book.coverThumbnailData)
        XCTAssertNil(book.coverFullData)
    }
}
