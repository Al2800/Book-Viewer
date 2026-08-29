import XCTest
@testable import BookQuotes

final class ActiveReadingSessionStoreTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test_active_reading_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        super.tearDown()
    }

    func testPersistsAndLoadsActiveBookID() {
        let store = ActiveReadingSessionStore(userDefaults: testDefaults)
        let bookID = UUID()

        XCTAssertNil(store.activeBookID)
        store.activeBookID = bookID
        XCTAssertEqual(store.activeBookID, bookID)

        let reloadedStore = ActiveReadingSessionStore(userDefaults: testDefaults)
        XCTAssertEqual(reloadedStore.activeBookID, bookID)

        store.clearActiveBook()
        XCTAssertNil(store.activeBookID)
    }

    func testResolvesPersistedBookFirst() {
        let store = ActiveReadingSessionStore(userDefaults: testDefaults)
        let book1 = Book(title: "Book 1", author: "Author 1")
        let book2 = Book(title: "Book 2", author: "Author 2")
        book2.status = .currentlyReading

        store.activeBookID = book1.id

        let resolved = store.resolveActiveBook(from: [book1, book2])
        XCTAssertEqual(resolved?.id, book1.id)
    }

    func testResolvesCurrentlyReadingBookWhenNoPersistedID() {
        let store = ActiveReadingSessionStore(userDefaults: testDefaults)
        let book1 = Book(title: "Book 1", author: "Author 1")
        book1.status = .finished

        let book2 = Book(title: "Book 2", author: "Author 2")
        book2.status = .currentlyReading

        let resolved = store.resolveActiveBook(from: [book1, book2])
        XCTAssertEqual(resolved?.id, book2.id)
        XCTAssertEqual(store.activeBookID, book2.id)
    }

    func testResolvesMostRecentBookWhenNoCurrentlyReadingBooks() {
        let store = ActiveReadingSessionStore(userDefaults: testDefaults)
        let book1 = Book(title: "Book 1", author: "Author 1")
        book1.dateModified = Date().addingTimeInterval(-100)

        let book2 = Book(title: "Book 2", author: "Author 2")
        book2.dateModified = Date()

        let resolved = store.resolveActiveBook(from: [book1, book2])
        XCTAssertEqual(resolved?.id, book2.id)
    }

    func testReturnsNilForEmptyBookList() {
        let store = ActiveReadingSessionStore(userDefaults: testDefaults)
        let resolved = store.resolveActiveBook(from: [])
        XCTAssertNil(resolved)
    }
}
