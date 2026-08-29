import XCTest
import SwiftUI
@testable import BookQuotes

final class OrganizationFilterBarTests: XCTestCase {

    func testQuotesFilterByCollections() {
        let coll1 = Collection(name: "Philosophy", icon: "book", colorName: "Sage")
        let coll2 = Collection(name: "Sci-Fi", icon: "sparkles", colorName: "Navy")

        let quote1 = Quote(text: "Meditations quote")
        quote1.collections = [coll1]

        let quote2 = Quote(text: "Dune quote")
        quote2.collections = [coll2]

        let quotes = [quote1, quote2]

        let filtered = quotes.filtered(byCollectionIds: [coll1.id], tagIds: [])
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.text, "Meditations quote")
    }

    func testQuotesFilterByTags() {
        let tag1 = Tag(name: "Mindset", colorName: "Sage")
        let tag2 = Tag(name: "Leadership", colorName: "Rust")

        let quote1 = Quote(text: "Growth mindset quote")
        quote1.tags = [tag1]

        let quote2 = Quote(text: "Leader quote")
        quote2.tags = [tag2]

        let quotes = [quote1, quote2]

        let filtered = quotes.filtered(byCollectionIds: [], tagIds: [tag2.id])
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.text, "Leader quote")
    }

    func testBooksFilterByCollectionsAndTags() {
        let coll = Collection(name: "Favorites", icon: "star", colorName: "Gold")
        let tag = Tag(name: "Productivity", colorName: "Plum")

        let book1 = Book(title: "Atomic Habits", author: "James Clear")
        let q1 = Quote(text: "Habits quote", book: book1)
        q1.collections = [coll]
        book1.quotes = [q1]

        let book2 = Book(title: "Deep Work", author: "Cal Newport")
        let q2 = Quote(text: "Focus quote", book: book2)
        q2.tags = [tag]
        book2.quotes = [q2]

        let books = [book1, book2]

        let filteredColl = books.filtered(byCollectionIds: [coll.id], tagIds: [])
        XCTAssertEqual(filteredColl.map(\.title), ["Atomic Habits"])

        let filteredTag = books.filtered(byCollectionIds: [], tagIds: [tag.id])
        XCTAssertEqual(filteredTag.map(\.title), ["Deep Work"])
    }
}
