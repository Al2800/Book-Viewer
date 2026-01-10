import XCTest

@testable import BookQuotes

// MARK: - SearchServiceTests

/// Unit tests for SearchService observable wrapper.
@MainActor
final class SearchServiceTests: FTS5TestCase {

    // MARK: - Properties

    var searchService: SearchService!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        searchService = SearchService(database: searchDatabase)
        logger.info("SearchService initialized with test database")
    }

    override func tearDown() async throws {
        searchService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSearchService_InitialState() async throws {
        XCTAssertTrue(searchService.results.isEmpty)
        XCTAssertFalse(searchService.isSearching)
        XCTAssertNil(searchService.lastError)

        logger.success("Initial state is correct")
    }

    // MARK: - Basic Search Tests

    func testSearchImmediate_ReturnsResults() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Success is the result of preparation"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("success")

        XCTAssertEqual(searchService.results.quotes.count, 1)
        XCTAssertFalse(searchService.isSearching)

        logger.success("Immediate search returns results")
    }

    func testSearchImmediate_EmptyQuery_ClearsResults() async throws {
        // First, add some results
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Test content here"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("test")
        XCTAssertFalse(searchService.results.isEmpty)

        // Now search with empty query
        await searchService.searchImmediate("")
        XCTAssertTrue(searchService.results.isEmpty)

        logger.success("Empty query clears results")
    }

    func testSearchImmediate_WhitespaceQuery_ClearsResults() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Some content"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("   ")
        XCTAssertTrue(searchService.results.isEmpty)

        logger.success("Whitespace query clears results")
    }

    // MARK: - Debounce Tests

    func testSearch_Debounce_OnlyLastQueryExecuted() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Final result here"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(1, "Rapid-fire multiple searches")
        searchService.search("first", scope: .all)
        searchService.search("second", scope: .all)
        searchService.search("final", scope: .all)

        logger.step(2, "Wait for debounce")
        try await Task.sleep(for: .milliseconds(300))

        logger.step(3, "Verify only last search executed")
        XCTAssertEqual(searchService.results.query, "final")

        logger.success("Debounce works correctly")
    }

    // MARK: - Cancellation Tests

    func testSearch_Cancel_NewSearchCancelsPrevious() async throws {
        logger.info("Testing search cancellation")

        searchService.search("long running query", scope: .all)
        searchService.search("new query", scope: .all)

        try await Task.sleep(for: .milliseconds(300))

        // Only the new query should complete
        XCTAssertEqual(searchService.results.query, "new query")

        logger.success("Previous search cancelled")
    }

    func testCancelSearch_StopsActiveSearch() async throws {
        searchService.search("test query")

        // Cancel immediately
        searchService.cancelSearch()

        XCTAssertFalse(searchService.isSearching)

        logger.success("Cancel search works")
    }

    // MARK: - State Tests

    func testSearch_IsSearching_UpdatesDuringSearch() async throws {
        XCTAssertFalse(searchService.isSearching)

        searchService.search("test", scope: .all)

        // After debounce completes
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(searchService.isSearching)

        logger.success("isSearching state updates correctly")
    }

    func testClearResults_ResetsState() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Content to search"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("content")
        XCTAssertFalse(searchService.results.isEmpty)

        searchService.clearResults()

        XCTAssertTrue(searchService.results.isEmpty)
        XCTAssertNil(searchService.lastError)
        XCTAssertFalse(searchService.isSearching)

        logger.success("Clear results works")
    }

    // MARK: - Scope Tests

    func testSearchImmediate_ScopeQuotes_OnlyQuotes() async throws {
        let book = TestFixtures.book { b in
            b.title = "Matching Title"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Matching text in quote"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("Matching", scope: .quotes)

        XCTAssertEqual(searchService.results.books.count, 0)

        logger.success("Quote scope works")
    }

    func testSearchImmediate_ScopeBooks_OnlyBooks() async throws {
        let book = TestFixtures.book { b in
            b.title = "Unique Book Name"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Quote about unique topic"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("unique", scope: .books)

        XCTAssertEqual(searchService.results.quotes.count, 0)
        XCTAssertEqual(searchService.results.books.count, 1)

        logger.success("Book scope works")
    }

    // MARK: - Index Management Tests

    func testIndexQuote_AddsToIndex() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Newly indexed quote"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()

        // Index via service
        await searchService.indexBook(book)
        await searchService.indexQuote(quote, book: book)

        // Verify searchable
        await searchService.searchImmediate("indexed")
        XCTAssertEqual(searchService.results.quotes.count, 1)

        logger.success("Index quote works")
    }

    func testRemoveQuoteFromIndex_RemovesFromSearch() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Quote to be removed"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        // Verify it's searchable
        await searchService.searchImmediate("removed")
        XCTAssertEqual(searchService.results.quotes.count, 1)

        // Remove from index
        await searchService.removeQuoteFromIndex(id: quote.id)

        // Verify not searchable
        await searchService.searchImmediate("removed")
        XCTAssertEqual(searchService.results.quotes.count, 0)

        logger.success("Remove quote from index works")
    }

    func testRemoveBookFromIndex_RemovesBookAndQuotes() async throws {
        let book = TestFixtures.book { b in
            b.title = "Removable Book"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Quote in removable book"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        // Verify searchable
        await searchService.searchImmediate("Removable", scope: .books)
        XCTAssertEqual(searchService.results.books.count, 1)

        // Remove book from index
        await searchService.removeBookFromIndex(id: book.id)

        // Verify not searchable
        await searchService.searchImmediate("Removable", scope: .all)
        XCTAssertEqual(searchService.results.books.count, 0)
        XCTAssertEqual(searchService.results.quotes.count, 0)

        logger.success("Remove book from index works")
    }

    func testRebuildIndex_ReindexesAll() async throws {
        let book1 = TestFixtures.book { b in b.title = "Book One" }
        let book2 = TestFixtures.book { b in b.title = "Book Two" }

        try insertBooks([book1, book2])

        await searchService.rebuildIndex(books: [book1, book2])

        let count = await searchService.indexedBooksCount
        XCTAssertEqual(count, 2)

        logger.success("Rebuild index works")
    }

    // MARK: - Statistics Tests

    func testIndexedQuotesCount_ReturnsCorrectCount() async throws {
        let book = TestFixtures.book()
        try insertBook(book)

        for i in 1...3 {
            let quote = TestFixtures.quote { q in
                q.text = "Quote \(i)"
                q.book = book
            }
            modelContext.insert(quote)
        }
        try modelContext.save()
        try await indexBook(book)

        let count = await searchService.indexedQuotesCount
        XCTAssertEqual(count, 3)

        logger.success("Indexed quotes count works")
    }

    func testIndexedBooksCount_ReturnsCorrectCount() async throws {
        for i in 1...2 {
            let book = TestFixtures.book { b in b.title = "Book \(i)" }
            try insertBook(book)
            try await indexBook(book)
        }

        let count = await searchService.indexedBooksCount
        XCTAssertEqual(count, 2)

        logger.success("Indexed books count works")
    }

    // MARK: - Error Handling Tests

    func testSearchImmediate_NoMatchingResults_EmptyResults() async throws {
        let book = TestFixtures.book()
        try insertBook(book)
        try await indexBook(book)

        await searchService.searchImmediate("nonexistentterm12345")

        XCTAssertTrue(searchService.results.isEmpty)
        XCTAssertNil(searchService.lastError)

        logger.success("No matching results returns empty without error")
    }

    // MARK: - Results Query Property Tests

    func testSearchResults_QueryPropertySet() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Test content"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("test")

        XCTAssertEqual(searchService.results.query, "test")

        logger.success("Results query property set correctly")
    }

    // MARK: - Total Count Tests

    func testSearchResults_TotalCount() async throws {
        let book = TestFixtures.book { b in
            b.title = "Searchable Title"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Searchable quote content"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        await searchService.searchImmediate("Searchable")

        XCTAssertEqual(searchService.results.totalCount, 2) // 1 book + 1 quote

        logger.success("Total count includes both books and quotes")
    }
}
