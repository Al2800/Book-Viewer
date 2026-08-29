import XCTest
import SwiftUI
@testable import BookQuotes

final class LibraryOverviewViewsTests: XCTestCase {

    func testDailyPassageReturnsDeterministicPick() {
        let book = Book(title: "Atomic Habits", author: "James Clear")
        let quote1 = Quote(text: "Quote 1", book: book)
        let quote2 = Quote(text: "Quote 2", book: book)
        let quote3 = Quote(text: "Quote 3", book: book)

        let quotes = [quote1, quote2, quote3]
        let date = Date(timeIntervalSince1970: 1700000000)

        let pick1 = DailyPassage.passage(from: quotes, on: date)
        let pick2 = DailyPassage.passage(from: quotes, on: date)

        XCTAssertNotNil(pick1)
        XCTAssertEqual(pick1?.id, pick2?.id)
    }

    func testDailyPassageFavorsFavorites() {
        let book = Book(title: "Meditations", author: "Marcus Aurelius")
        let nonFav = Quote(text: "Non favorite", book: book)
        nonFav.isFavorite = false
        let fav = Quote(text: "Favorite passage", book: book)
        fav.isFavorite = true

        let pick = DailyPassage.passage(from: [nonFav, fav])
        XCTAssertEqual(pick?.id, fav.id)
    }

    func testDailyPassageReturnsNilWhenEmpty() {
        let pick = DailyPassage.passage(from: [])
        XCTAssertNil(pick)
    }

    func testLibraryHomeSnapshotComputesCorrectly() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        let quote = Quote(text: "Fear is the mind-killer", book: book)
        book.quotes = [quote]

        let snapshot = LibraryHomeSnapshot(books: [book])
        XCTAssertEqual(snapshot.totalQuoteCount, 1)
        XCTAssertEqual(snapshot.dailyPassage?.id, quote.id)
    }
}
