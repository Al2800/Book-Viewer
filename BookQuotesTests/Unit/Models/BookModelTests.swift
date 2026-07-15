import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - BookModelTests

/// Comprehensive unit tests for Book SwiftData model.
@MainActor
final class BookModelTests: SwiftDataTestCase {

    // MARK: - Creation Tests

    func testBookCreation_WithRequiredFields_Succeeds() async throws {
        logger.step(1, "Creating book with required fields only")
        let book = Book(title: "Test Title", author: "Test Author")

        logger.step(2, "Verifying default values")
        XCTAssertNotNil(book.id)
        XCTAssertEqual(book.title, "Test Title")
        XCTAssertEqual(book.author, "Test Author")
        XCTAssertEqual(book.status, .wantToRead)
        XCTAssertEqual(book.quoteCount, 0)
        XCTAssertNotNil(book.dateAdded)
        XCTAssertNotNil(book.dateModified)
        XCTAssertNil(book.subtitle)
        XCTAssertNil(book.isbn)

        logger.success("Book creation with defaults works")
    }

    func testBookCreation_WithAllFields_Succeeds() async throws {
        logger.step(1, "Creating book with all fields")
        let book = TestFixtures.book { b in
            b.title = "Complete Book"
            b.author = "Full Author"
            b.subtitle = "A Subtitle"
            b.isbn = "978-1234567890"
            b.status = .currentlyReading
        }

        logger.step(2, "Inserting and fetching")
        try insertBook(book)
        let fetched = try XCTUnwrap(fetchAllBooks().first)

        logger.step(3, "Verifying all fields persisted")
        XCTAssertEqual(fetched.title, "Complete Book")
        XCTAssertEqual(fetched.author, "Full Author")
        XCTAssertEqual(fetched.subtitle, "A Subtitle")
        XCTAssertEqual(fetched.isbn, "978-1234567890")
        XCTAssertEqual(fetched.status, .currentlyReading)

        logger.success("All book fields persist correctly")
    }

    func testBookCreation_WithOptionalFields_Nil() async throws {
        logger.step(1, "Creating book with only required fields")
        let book = Book(title: "Simple Book", author: "Simple Author")
        try insertBook(book)

        logger.step(2, "Fetching and verifying nil optionals")
        let fetched = try XCTUnwrap(fetchAllBooks().first)

        XCTAssertNil(fetched.subtitle)
        XCTAssertNil(fetched.publisher)
        XCTAssertNil(fetched.isbn)
        XCTAssertNil(fetched.pageCount)
        XCTAssertNil(fetched.publishYear)
        XCTAssertNil(fetched.genre)
        XCTAssertNil(fetched.coverThumbnailData)
        XCTAssertNil(fetched.coverFullData)
        XCTAssertNil(fetched.dateStarted)
        XCTAssertNil(fetched.dateFinished)
        XCTAssertNil(fetched.notes)
        XCTAssertNil(fetched.rating)

        logger.success("Optional fields correctly nil")
    }

    // MARK: - Relationship Tests

    func testBookQuoteRelationship_BidirectionalLink() async throws {
        logger.step(1, "Creating book and quotes")
        let book = TestFixtures.book()
        let quote1 = TestFixtures.quote { q in q.book = book }
        let quote2 = TestFixtures.quote { q in q.book = book }

        logger.step(2, "Inserting into context")
        modelContext.insert(book)
        modelContext.insert(quote1)
        modelContext.insert(quote2)
        try modelContext.save()

        logger.step(3, "Verifying book -> quotes")
        XCTAssertEqual(book.quotes.count, 2)
        XCTAssertEqual(book.quoteCount, 2)
        XCTAssertTrue(book.hasQuotes)

        logger.step(4, "Verifying quote -> book")
        XCTAssertEqual(quote1.book?.id, book.id)
        XCTAssertEqual(quote2.book?.id, book.id)

        logger.success("Bidirectional relationship works")
    }

    func testBookDeletion_CascadesToQuotes() async throws {
        logger.step(1, "Creating book with quotes")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in q.book = book }

        modelContext.insert(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(2, "Verifying quote exists")
        try assertQuoteCount(1)

        logger.step(3, "Deleting book")
        modelContext.delete(book)
        try modelContext.save()

        logger.step(4, "Verifying quotes deleted")
        try assertQuoteCount(0)

        logger.success("Cascade delete works")
    }

    func testBookWithMultipleQuotes_CountUpdates() async throws {
        logger.step(1, "Creating book with multiple quotes")
        let book = TestFixtures.book()
        modelContext.insert(book)

        for i in 1...5 {
            let quote = TestFixtures.quote { q in
                q.text = "Quote \(i)"
                q.book = book
            }
            modelContext.insert(quote)
        }
        try modelContext.save()

        logger.step(2, "Verifying quote count")
        XCTAssertEqual(book.quoteCount, 5)
        XCTAssertTrue(book.hasQuotes)

        logger.success("Quote count updates correctly")
    }

    // MARK: - Status Tests

    func testBookStatus_AllValuesValid() async throws {
        for status in ReadingStatus.allCases {
            logger.debug("Testing status: \(status.rawValue)")
            let book = TestFixtures.book { b in b.status = status }
            try insertBook(book)

            let fetched = try XCTUnwrap(fetchAllBooks().last)
            XCTAssertEqual(fetched.status, status)

            modelContext.delete(fetched)
            try modelContext.save()
        }
        logger.success("All reading statuses persist correctly")
    }

    func testBookStatus_DefaultIsWantToRead() async throws {
        let book = Book(title: "New Book", author: "Author")
        XCTAssertEqual(book.status, .wantToRead)
        logger.success("Default status is wantToRead")
    }

    // MARK: - Cover Image Tests

    func testBookCoverImage_StoresAndRetrieves() async throws {
        logger.step(1, "Creating book with cover image")
        let coverData = TestFixtures.TestImages.bookCover
        let book = TestFixtures.book { b in b.coverThumbnailData = coverData }

        logger.step(2, "Inserting and fetching")
        try insertBook(book)
        let fetched = try XCTUnwrap(fetchAllBooks().first)

        logger.step(3, "Verifying image data matches")
        XCTAssertNotNil(fetched.coverThumbnailData)
        XCTAssertEqual(fetched.coverThumbnailData?.count, coverData.count)

        logger.success("Cover image persists correctly")
    }

    func testBookCoverImage_NilByDefault() async throws {
        let book = Book(title: "No Cover", author: "Author")
        try insertBook(book)

        let fetched = try XCTUnwrap(fetchAllBooks().first)
        XCTAssertNil(fetched.coverThumbnailData)
        XCTAssertNil(fetched.coverFullData)

        logger.success("Default cover image state persists")
    }

    // MARK: - Date Tests

    func testBookDates_SetOnCreation() async throws {
        let before = Date()
        let book = Book(title: "Test", author: "Author")
        let after = Date()

        XCTAssertGreaterThanOrEqual(book.dateAdded, before)
        XCTAssertLessThanOrEqual(book.dateAdded, after)
        XCTAssertGreaterThanOrEqual(book.dateModified, before)
        XCTAssertLessThanOrEqual(book.dateModified, after)

        logger.success("Dates set correctly on creation")
    }

    func testBookDates_OptionalDatesNil() async throws {
        let book = Book(title: "Test", author: "Author")
        XCTAssertNil(book.dateStarted)
        XCTAssertNil(book.dateFinished)
        XCTAssertNil(book.dateLastQuoteAdded)

        logger.success("Optional dates nil by default")
    }

    // MARK: - Validation Tests

    func testBookValidation_EmptyTitle_Throws() async throws {
        let book = Book(title: "  ", author: "Author")

        XCTAssertThrowsError(try book.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyTitle)
        }

        logger.success("Empty title validation works")
    }

    func testBookValidation_EmptyAuthor_Throws() async throws {
        let book = Book(title: "Title", author: "   ")

        XCTAssertThrowsError(try book.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .emptyAuthor)
        }

        logger.success("Empty author validation works")
    }

    func testBookValidation_InvalidRating_Throws() async throws {
        let book = Book(title: "Title", author: "Author")
        book.rating = 6 // Out of 1-5 range

        XCTAssertThrowsError(try book.validate()) { error in
            XCTAssertEqual(error as? ValidationError, .invalidRating)
        }

        logger.success("Invalid rating validation works")
    }

    func testBookValidation_ValidBook_NoThrow() async throws {
        let book = Book(title: "Valid Title", author: "Valid Author")
        book.rating = 4

        XCTAssertNoThrow(try book.validate())

        logger.success("Valid book passes validation")
    }

    // MARK: - Query Descriptor Tests

    func testBookQuery_RecentlyAdded() async throws {
        logger.step(1, "Creating books at different times")
        let book1 = Book(title: "First", author: "A")
        try insertBook(book1)

        // Small delay to ensure different timestamps
        try await Task.sleep(for: .milliseconds(10))

        let book2 = Book(title: "Second", author: "B")
        try insertBook(book2)

        logger.step(2, "Fetching with recentlyAdded descriptor")
        let fetched = try modelContext.fetch(Book.recentlyAdded)

        logger.step(3, "Verifying order (newest first)")
        XCTAssertEqual(fetched.first?.title, "Second")

        logger.success("RecentlyAdded query works")
    }

    func testBookQuery_CurrentlyReading() async throws {
        logger.step(1, "Creating books with different statuses")
        let reading = TestFixtures.book { $0.status = .currentlyReading }
        let finished = TestFixtures.book { $0.status = .finished; $0.title = "Finished" }

        try insertBooks([reading, finished])

        logger.step(2, "Fetching with currentlyReading descriptor")
        let fetched = try modelContext.fetch(Book.currentlyReading)

        logger.step(3, "Verifying only reading books returned")
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.status, .currentlyReading)

        logger.success("CurrentlyReading query works")
    }

    // MARK: - UUID Uniqueness Tests

    func testBook_HasUniqueID() async throws {
        let book1 = Book(title: "Book 1", author: "Author")
        let book2 = Book(title: "Book 2", author: "Author")

        XCTAssertNotEqual(book1.id, book2.id)

        logger.success("Each book has unique ID")
    }

    // MARK: - Collection and Tag Relationship Tests

    func testBook_CollectionsRelationship_InitEmpty() async throws {
        let book = Book(title: "Test", author: "Author")
        XCTAssertTrue(book.collections.isEmpty)
        logger.success("Collections empty by default")
    }

    func testBook_TagsRelationship_InitEmpty() async throws {
        let book = Book(title: "Test", author: "Author")
        XCTAssertTrue(book.tags.isEmpty)
        logger.success("Tags empty by default")
    }
}
