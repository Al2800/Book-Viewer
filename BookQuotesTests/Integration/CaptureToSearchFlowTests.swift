import XCTest
import SwiftData

@testable import BookQuotes

/// Integration tests verifying the complete flow from data creation to search.
/// Tests real SwiftData + FTS5 working together.
@MainActor
final class CaptureToSearchFlowTests: FTS5TestCase {

    // MARK: - Complete Flow Tests

    func testFlow_AddBook_BecomeSearchable() async throws {
        logger.step(1, "Creating a new book")
        let book = TestFixtures.book { b in
            b.title = "The Happiness Project"
            b.author = "Gretchen Rubin"
        }

        logger.step(2, "Saving to SwiftData")
        try insertBook(book)

        logger.step(3, "Indexing in FTS5")
        try await searchDatabase.indexBook(book)

        logger.step(4, "Searching for book")
        let results = try await search("Happiness Project", scope: .books)

        logger.step(5, "Verifying book found")
        XCTAssertEqual(results.books.count, 1)
        XCTAssertEqual(results.books.first?.bookId, book.id)

        logger.success("Book flows from creation to search")
    }

    func testFlow_AddQuote_BecomeSearchable() async throws {
        logger.step(1, "Creating book and quote")
        let book = TestFixtures.atomicHabits
        let quote = TestFixtures.quote { q in
            q.text = "Every action you take is a vote for the type of person you wish to become"
            q.pageNumber = 38
            q.book = book
        }

        logger.step(2, "Saving to SwiftData")
        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()

        logger.step(3, "Indexing in FTS5")
        try await indexBook(book)

        logger.step(4, "Searching for quote text")
        try await assertSearchCount("vote for the type of person", scope: .quotes, expectedQuotes: 1)

        logger.success("Quote flows from creation to search")
    }

    func testFlow_UpdateQuote_SearchReflectsChange() async throws {
        logger.step(1, "Creating and indexing initial quote")
        let book = TestFixtures.book { b in
            b.title = "Test Book"
            b.author = "Test Author"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Original text about happiness"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Verifying original text searchable")
        try await assertSearchCount("happiness", expectedQuotes: 1)

        logger.step(3, "Updating quote text")
        quote.text = "New text about discipline"
        try modelContext.save()

        logger.step(4, "Re-indexing quote")
        try await searchDatabase.indexQuote(quote, book: book)

        logger.step(5, "Verifying new text searchable")
        try await assertSearchCount("discipline", expectedQuotes: 1)

        logger.step(6, "Verifying old text NOT searchable")
        try await assertSearchCount("happiness", expectedQuotes: 0)

        logger.success("Quote update reflected in search")
    }

    func testFlow_DeleteQuote_RemovedFromSearch() async throws {
        logger.step(1, "Creating and indexing quote")
        let book = TestFixtures.book { b in
            b.title = "Deletable Book"
            b.author = "Author"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Temporary quote to delete"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Verifying quote searchable")
        try await assertSearchCount("Temporary", expectedQuotes: 1)

        logger.step(3, "Deleting quote from SwiftData")
        let quoteId = quote.id
        modelContext.delete(quote)
        try modelContext.save()

        logger.step(4, "Removing from search index")
        try await searchDatabase.removeQuote(id: quoteId)

        logger.step(5, "Verifying quote NOT searchable")
        try await assertSearchCount("Temporary", expectedQuotes: 0)

        logger.success("Deleted quote removed from search")
    }

    // MARK: - Multiple Items Flow

    func testFlow_MultipleBooks_AllSearchable() async throws {
        logger.step(1, "Creating multiple books")
        let books = [
            TestFixtures.atomicHabits,
            TestFixtures.deepWork,
            TestFixtures.thinkingFastAndSlow
        ]

        logger.step(2, "Saving and indexing all books")
        try insertBooks(books)
        try await indexBooks(books)

        logger.step(3, "Searching for each book")
        try await assertSearchCount("Atomic", expectedBooks: 1)
        try await assertSearchCount("Deep", expectedBooks: 1)
        try await assertSearchCount("Thinking", expectedBooks: 1)

        logger.success("All books searchable")
    }

    func testFlow_QuotesAcrossBooks_AllSearchable() async throws {
        logger.step(1, "Creating books with quotes")
        let book1 = TestFixtures.book { b in b.title = "Book One"; b.author = "Author One" }
        let book2 = TestFixtures.book { b in b.title = "Book Two"; b.author = "Author Two" }

        let quote1 = TestFixtures.quote { q in
            q.text = "Unique phrase alpha"
            q.book = book1
        }
        let quote2 = TestFixtures.quote { q in
            q.text = "Unique phrase beta"
            q.book = book2
        }

        logger.step(2, "Saving all data")
        modelContext.insert(book1)
        modelContext.insert(book2)
        modelContext.insert(quote1)
        modelContext.insert(quote2)
        try modelContext.save()

        logger.step(3, "Indexing all")
        try await indexBooks([book1, book2])

        logger.step(4, "Searching across books")
        try await assertSearchCount("alpha", expectedQuotes: 1)
        try await assertSearchCount("beta", expectedQuotes: 1)
        try await assertSearchCount("Unique phrase", expectedQuotes: 2)

        logger.success("Quotes across books all searchable")
    }

    // MARK: - Index Synchronization Tests

    func testFlow_RebuildIndex_RestoresAllData() async throws {
        logger.step(1, "Creating test data")
        let book = TestFixtures.atomicHabits
        let quotes = [
            TestFixtures.quote { q in
                q.text = "First important quote"
                q.book = book
            },
            TestFixtures.quote { q in
                q.text = "Second important quote"
                q.book = book
            },
            TestFixtures.quote { q in
                q.text = "Third important quote"
                q.book = book
            }
        ]

        logger.step(2, "Saving to SwiftData")
        try insertBook(book)
        for quote in quotes {
            modelContext.insert(quote)
        }
        try modelContext.save()

        logger.step(3, "Initial indexing")
        try await indexBook(book)
        try await assertIndexCounts(quotes: 3, books: 1)

        logger.step(4, "Clearing index (simulating corruption)")
        try await searchDatabase.rebuildIndex(books: [])
        try await assertIndexCounts(quotes: 0, books: 0)

        logger.step(5, "Rebuilding from SwiftData")
        try await searchDatabase.rebuildIndex(books: [book])

        logger.step(6, "Verifying restoration")
        try await assertIndexCounts(quotes: 3, books: 1)
        try await assertSearchCount("important", expectedQuotes: 3)

        logger.success("Index rebuild restores all data")
    }

    func testFlow_DeleteBook_RemovesBookAndQuotes() async throws {
        logger.step(1, "Creating book with quotes")
        let book = TestFixtures.book { b in
            b.title = "Removable Book"
            b.author = "Temporary Author"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Quote belonging to removable book"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Verifying indexed")
        try await assertSearchCount("Removable", expectedBooks: 1)
        try await assertSearchCount("belonging", expectedQuotes: 1)

        logger.step(3, "Removing from index")
        try await searchDatabase.removeBook(id: book.id)

        logger.step(4, "Verifying removed")
        try await assertSearchCount("Removable", expectedBooks: 0)
        try await assertSearchCount("belonging", expectedQuotes: 0)

        logger.success("Book deletion removes book and quotes from index")
    }

    // MARK: - Concurrent Operations

    func testFlow_ConcurrentSearches_AllComplete() async throws {
        logger.step(1, "Setting up test data")
        let books = TestFixtures.largeBookCollection(bookCount: 5, quotesPerBook: 5)
        try insertBooks(books)
        try await indexBooks(books)

        logger.step(2, "Launching concurrent searches")
        async let search1 = searchDatabase.search(query: "happiness", scope: .all)
        async let search2 = searchDatabase.search(query: "success", scope: .all)
        async let search3 = searchDatabase.search(query: "growth", scope: .all)

        let results = try await [search1, search2, search3]

        logger.step(3, "Verifying all searches completed")
        XCTAssertEqual(results.count, 3)

        for (index, result) in results.enumerated() {
            logger.debug("Search \(index + 1) completed", context: [
                "books": "\(result.books.count)",
                "quotes": "\(result.quotes.count)"
            ])
        }

        logger.success("Concurrent searches all complete")
    }

    func testFlow_ConcurrentIndexAndSearch_NoDeadlock() async throws {
        logger.step(1, "Creating initial data")
        let book1 = TestFixtures.atomicHabits
        try insertBook(book1)
        try await indexBook(book1)

        logger.step(2, "Running concurrent indexing and searching")
        async let searchTask: () = Task {
            for _ in 0..<10 {
                let _ = try? await self.searchDatabase.search(query: "habits", scope: .all)
            }
        }.value

        async let indexTask: () = Task { @MainActor in
            let newBook = TestFixtures.deepWork
            self.modelContext.insert(newBook)
            try? self.modelContext.save()
            try? await self.indexBook(newBook)
        }.value

        // Both tasks should complete without deadlock
        _ = await (searchTask, indexTask)

        logger.step(3, "Verifying data integrity")
        let count = try await indexedBooksCount()
        XCTAssertGreaterThanOrEqual(count, 1)

        logger.success("Concurrent operations completed without deadlock")
    }

    // MARK: - Edge Cases

    func testFlow_EmptySearch_ReturnsNoResults() async throws {
        logger.step(1, "Creating indexed data")
        let book = TestFixtures.atomicHabits
        try insertBook(book)
        try await indexBook(book)

        logger.step(2, "Searching for non-existent term")
        let results = try await search("xyzzynonexistent123", scope: .all)

        logger.step(3, "Verifying empty results")
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(results.totalCount, 0)

        logger.success("Empty search returns no results")
    }

    func testFlow_SpecialCharacters_HandledGracefully() async throws {
        logger.step(1, "Creating book with special characters in title")
        let book = TestFixtures.book { b in
            b.title = "C++ Programming: A Modern Approach"
            b.author = "O'Brien & Co."
        }

        try insertBook(book)
        try await searchDatabase.indexBook(book)

        logger.step(2, "Searching with special characters")
        // FTS5 should handle this gracefully
        let results = try await search("Modern Approach", scope: .books)

        logger.step(3, "Verifying book found")
        XCTAssertEqual(results.books.count, 1)

        logger.success("Special characters handled gracefully")
    }

    func testFlow_PrefixSearch_FindsPartialMatches() async throws {
        logger.step(1, "Creating data")
        let book = TestFixtures.book { b in
            b.title = "Programming Principles"
            b.author = "Developer"
        }

        try insertBook(book)
        try await searchDatabase.indexBook(book)

        logger.step(2, "Searching with prefix")
        // Should find "Programming" with prefix "Prog"
        let results = try await search("Prog", scope: .books)

        logger.step(3, "Verifying prefix match")
        XCTAssertEqual(results.books.count, 1)

        logger.success("Prefix search finds partial matches")
    }
}
