import XCTest

@testable import BookQuotes

final class QuoteTagMutationTests: XCTestCase {

    func testAddTagMaintainsBothSidesAndUpdatesQuoteModifiedDate() {
        let quote = Quote(text: "A quote long enough to carry a tag.")
        let tag = Tag(name: "Productivity")
        let modifiedDate = Date(timeIntervalSince1970: 2_000)

        QuoteTagMutation(modifiedDate: modifiedDate).add(tag, to: quote)

        XCTAssertEqual(quote.tags.map(\.id), [tag.id])
        XCTAssertEqual(tag.quotes.map(\.id), [quote.id])
        XCTAssertEqual(quote.dateModified, modifiedDate)
    }

    func testRemoveTagMaintainsBothSidesAndUpdatesQuoteModifiedDate() {
        let quote = Quote(text: "A quote long enough to remove a tag from.")
        let tag = Tag(name: "Productivity")
        quote.tags.append(tag)
        tag.quotes.append(quote)
        let modifiedDate = Date(timeIntervalSince1970: 2_001)

        QuoteTagMutation(modifiedDate: modifiedDate).remove(tag, from: quote)

        XCTAssertTrue(quote.tags.isEmpty)
        XCTAssertTrue(tag.quotes.isEmpty)
        XCTAssertEqual(quote.dateModified, modifiedDate)
    }
}
