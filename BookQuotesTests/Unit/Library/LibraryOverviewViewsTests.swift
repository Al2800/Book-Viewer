import XCTest
import SwiftUI
@testable import BookQuotes

@MainActor
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
        XCTAssertNil(snapshot.dailyPassage)
        XCTAssertEqual(snapshot.recentQuotes.map(\.id), [quote.id])
        XCTAssertEqual(snapshot.activeBook?.id, book.id)
    }

    func testLibraryHomeSnapshotDeduplicatesRecentQuotesAgainstDailyPassage() {
        let book = Book(title: "Dune", author: "Frank Herbert")
        let quote1 = Quote(text: "Fear is the mind-killer", book: book)
        let quote2 = Quote(text: "I must not fear", book: book)
        let quote3 = Quote(text: "Fear is the little-death", book: book)
        quote1.captureDate = Date(timeIntervalSince1970: 1000)
        quote2.captureDate = Date(timeIntervalSince1970: 2000)
        quote3.captureDate = Date(timeIntervalSince1970: 3000)
        book.quotes = [quote1, quote2, quote3]

        let snapshot = LibraryHomeSnapshot(books: [book])
        if let dailyID = snapshot.dailyPassage?.id {
            XCTAssertFalse(snapshot.recentQuotes.contains(where: { $0.id == dailyID }))
        }
    }

    func testRecentPrecedesRevisitAndOnlyOlderPassagesAreEligible() {
        let book = Book(title: "Reading", author: "Reader")
        let quotes = (0..<6).map { index in
            let quote = Quote(text: "Passage \(index)", book: book)
            quote.captureDate = Date(timeIntervalSince1970: Double(index))
            return quote
        }
        book.quotes = quotes
        quotes[5].isFavorite = true // A favourite must not displace a recent item.
        let first = LibraryHomeSnapshot(books: [book])
        XCTAssertEqual(first.recentQuotes.map(\.id), [quotes[5].id, quotes[4].id, quotes[3].id])
        XCTAssertNotNil(first.dailyPassage)
        XCTAssertTrue(quotes.prefix(3).contains { $0.id == first.dailyPassage?.id })
        book.quotes = quotes.reversed()
        let reordered = LibraryHomeSnapshot(books: [book])
        XCTAssertEqual(reordered.recentQuotes.map(\.id), first.recentQuotes.map(\.id))
        XCTAssertEqual(reordered.dailyPassage?.id, first.dailyPassage?.id)
    }

    func testEqualDatePassagesAreNotMisrepresentedAsOlder() {
        let book = Book(title: "Reading", author: "Reader")
        book.quotes = (0..<5).map { index in
            let quote = Quote(text: "Passage \(index)", book: book)
            quote.captureDate = Date(timeIntervalSince1970: 1)
            return quote
        }
        let snapshot = LibraryHomeSnapshot(books: [book])
        XCTAssertEqual(snapshot.recentQuotes.count, 3)
        XCTAssertNil(snapshot.dailyPassage)
    }

    func testShelfGroupsIncludeEveryStatusOnceAndPreserveInputOrder() {
        let books = ReadingStatus.allCases.flatMap { status in
            (0..<2).map { index in
                let book = Book(title: "\(status.rawValue) \(index)", author: "Reader")
                book.status = status
                return book
            }
        }
        let groups = LibraryShelfGroup.groups(for: books)
        XCTAssertEqual(groups.first?.status, .currentlyReading)
        XCTAssertEqual(Set(groups.map(\.status)), Set(ReadingStatus.allCases))
        XCTAssertEqual(groups.flatMap(\.books).count, books.count)
        XCTAssertEqual(Set(groups.flatMap(\.books).map(\.id)), Set(books.map(\.id)))
        for group in groups {
            XCTAssertEqual(group.books.map(\.id), books.filter { $0.status == group.status }.map(\.id))
        }
    }

    func testShelfGroupsOmitEmptyStatusesButKeepAbandonedOnlyLibraries() {
        XCTAssertTrue(LibraryShelfGroup.groups(for: []).isEmpty)
        let book = Book(title: "Paused indefinitely", author: "Reader")
        book.status = .abandoned
        let groups = LibraryShelfGroup.groups(for: [book])
        XCTAssertEqual(groups.map(\.status), [.abandoned])
        XCTAssertEqual(groups.first?.books.map(\.id), [book.id])
    }

    func testActiveReadingSessionStorePureQueryDoesNotMutatePersistedID() {
        let suiteName = "test_library_snapshot_store_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ActiveReadingSessionStore(userDefaults: defaults)
        XCTAssertNil(store.activeBookID)

        let book = Book(title: "Deep Work", author: "Cal Newport")
        book.status = .currentlyReading

        let resolved = store.activeBook(from: [book])
        XCTAssertEqual(resolved?.id, book.id)
        XCTAssertNil(store.activeBookID)
    }
}
