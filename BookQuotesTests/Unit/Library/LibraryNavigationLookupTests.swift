import XCTest

@testable import BookQuotes

@MainActor
final class LibraryNavigationLookupTests: SwiftDataTestCase {
    func testFindsBookBySearchResultIdentifier() throws {
        let book = Book(title: "Searchable Book", author: "Reader")
        try insertBook(book)

        let lookup = LibraryNavigationLookup(modelContext: modelContext)

        XCTAssertEqual(lookup.book(id: book.id), book)
    }

    func testFindsQuoteBySearchResultIdentifier() throws {
        let book = Book(title: "Quote Source", author: "Reader")
        let quote = Quote(text: "A quote selected from search results.", book: book)
        try insertBook(book)
        try insertQuote(quote)

        let lookup = LibraryNavigationLookup(modelContext: modelContext)

        XCTAssertEqual(lookup.quote(id: quote.id), quote)
    }

    func testMissingIdentifiersReturnNil() throws {
        let lookup = LibraryNavigationLookup(modelContext: modelContext)

        XCTAssertNil(lookup.book(id: UUID()))
        XCTAssertNil(lookup.quote(id: UUID()))
    }
}
