import XCTest

@testable import BookQuotes

final class BookISBNScanLookupTests: XCTestCase {
    func testLookupReturnsFoundMetadata() async {
        let metadata = BookMetadata(
            title: "The Pragmatic Programmer",
            authors: ["David Thomas", "Andrew Hunt"],
            isbn13: "9780135957059",
            source: .googleBooks
        )
        let lookup = BookISBNScanLookup { isbn in
            XCTAssertEqual(isbn, "9780135957059")
            return metadata
        }

        let result = await lookup.lookup(isbn: "9780135957059")

        guard case .found(let foundMetadata) = result else {
            return XCTFail("Expected successful ISBN lookup")
        }
        XCTAssertEqual(foundMetadata.title, "The Pragmatic Programmer")
        XCTAssertEqual(foundMetadata.authorsFormatted, "David Thomas, Andrew Hunt")
        XCTAssertEqual(foundMetadata.bestISBN, "9780135957059")
    }

    func testLookupReturnsFailureError() async {
        let lookup = BookISBNScanLookup { _ in
            throw LookupError.notFound(isbn: "9780135957059")
        }

        let result = await lookup.lookup(isbn: "9780135957059")

        guard case .failed(let error) = result else {
            return XCTFail("Expected failed ISBN lookup")
        }
        XCTAssertEqual(error.localizedDescription, LookupError.notFound(isbn: "9780135957059").localizedDescription)
    }
}
