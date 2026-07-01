import XCTest

@testable import BookQuotes

final class BookISBNConfirmationDraftTests: XCTestCase {
    func testMakesBookFromEditedISBNMetadata() {
        let metadata = BookMetadata(
            title: "Original Title",
            subtitle: "Original Subtitle",
            authors: ["Original Author"],
            publisher: "Original Publisher",
            publishedYear: 2024,
            isbn13: "9780135957059",
            pageCount: 352,
            source: .googleBooks
        )
        let draft = BookISBNConfirmationDraft(
            title: "  Edited Title  ",
            author: "  Edited Author  ",
            subtitle: "   ",
            publisher: "  Edited Publisher  ",
            pageCount: "352",
            status: .finished,
            metadata: metadata,
            coverImageData: Data([1, 2, 3])
        )

        let book = draft.makeBook()

        XCTAssertEqual(book.title, "Edited Title")
        XCTAssertEqual(book.author, "Edited Author")
        XCTAssertNil(book.subtitle)
        XCTAssertEqual(book.publisher, "Edited Publisher")
        XCTAssertEqual(book.isbn, "9780135957059")
        XCTAssertEqual(book.publishYear, 2024)
        XCTAssertEqual(book.pageCount, 352)
        XCTAssertEqual(book.status, .finished)
        XCTAssertEqual(book.coverThumbnailData, Data([1, 2, 3]))
        XCTAssertEqual(book.coverFullData, Data([1, 2, 3]))
    }
}
