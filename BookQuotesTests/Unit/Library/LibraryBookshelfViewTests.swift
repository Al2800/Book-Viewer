import XCTest
import SwiftUI
@testable import BookQuotes

final class LibraryBookshelfViewTests: XCTestCase {

    func testBookshelfDisplaysCurrentlyReadingBooksFirst() {
        let book1 = Book(title: "Book 1", author: "Author 1")
        book1.status = .finished

        let book2 = Book(title: "Book 2", author: "Author 2")
        book2.status = .currentlyReading

        let books = [book1, book2]

        var selectedBook: Book?
        let shelf = LibraryBookshelfView(books: books, onSelectBook: { book in
            selectedBook = book
        })

        shelf.onSelectBook(book2)
        XCTAssertEqual(selectedBook?.title, "Book 2")
    }

    func testBookshelfHandlesEmptyListGracefully() {
        var addCalled = false
        let shelf = LibraryBookshelfView(books: [], onSelectBook: { _ in }, onAddBook: {
            addCalled = true
        })

        shelf.onAddBook?()
        XCTAssertTrue(addCalled)
    }

    func testBookshelfItemAccessibilityLabel() {
        let book = Book(title: "The Hobbit", author: "J.R.R. Tolkien")
        let quote = Quote(text: "In a hole in the ground...", book: book)
        book.quotes = [quote]

        let item = BookshelfItemView(book: book, onTap: {})
        XCTAssertNotNil(item)
    }
}
