import XCTest

@testable import BookQuotes

// MARK: - SearchDatabaseTests

/// Comprehensive unit tests for FTS5 search database functionality.
@MainActor
final class SearchDatabaseTests: FTS5TestCase {

    // MARK: - Indexing Tests

    func testIndexQuote_CreatesSearchableEntry() async throws {
        logger.step(1, "Creating and indexing a quote")
        let book = TestFixtures.book { b in
            b.title = "Test Book"
            b.author = "Test Author"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Happiness is the absence of desire"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Searching for indexed term")
        let results = try await search("happiness")

        XCTAssertEqual(results.quotes.count, 1)
        logger.success("Quote indexed and searchable")
    }

    func testIndexQuote_IncludesMarginNote() async throws {
        logger.step(1, "Creating quote with margin note")
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Main quote text here"
            q.marginNote = "Important insight about productivity"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(2, "Searching for term in margin note")
        let results = try await search("productivity")

        XCTAssertEqual(results.quotes.count, 1)
        logger.success("Margin note is searchable")
    }

    func testIndexBook_TitleAndAuthorSearchable() async throws {
        let book = TestFixtures.book { b in
            b.title = "Atomic Habits"
            b.author = "James Clear"
        }

        try insertBook(book)
        try await indexBook(book)

        logger.step(1, "Searching by title")
        try await assertSearchCount("Atomic", expectedBooks: 1)

        logger.step(2, "Searching by author")
        try await assertSearchCount("James", expectedBooks: 1)

        logger.success("Book title and author searchable")
    }

    func testIndexBook_SubtitleSearchable() async throws {
        let book = TestFixtures.book { b in
            b.title = "Deep Work"
            b.author = "Cal Newport"
            b.subtitle = "Rules for Focused Success"
        }

        try insertBook(book)
        try await indexBook(book)

        let results = try await search("Focused")
        XCTAssertEqual(results.books.count, 1)

        logger.success("Book subtitle is searchable")
    }

    // MARK: - Query Building Tests

    func testSearch_SingleWord_ExactMatch() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Success is the sum of small efforts"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("success")
        XCTAssertEqual(results.quotes.count, 1)

        logger.success("Single word exact match works")
    }

    func testSearch_MultipleWords_MatchesAll() async throws {
        let book = TestFixtures.book()
        let quote1 = TestFixtures.quote { q in
            q.text = "Success requires discipline and focus"
            q.book = book
        }
        let quote2 = TestFixtures.quote { q in
            q.text = "Discipline is the bridge to goals"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote1)
        modelContext.insert(quote2)
        try modelContext.save()
        try await indexBook(book)

        logger.step(1, "Searching 'success discipline' should match quote1")
        let results = try await search("success discipline")
        XCTAssertGreaterThanOrEqual(results.quotes.count, 1)

        logger.success("Multi-word search works")
    }

    func testSearch_PrefixMatch_InstantSearch() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Happiness comes from within"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(1, "Searching with prefix 'happ'")
        let results = try await search("happ")

        // Should match "happiness" via prefix
        XCTAssertEqual(results.quotes.count, 1)

        logger.success("Prefix matching works")
    }

    // MARK: - Stemming Tests (Porter)

    func testSearch_PorterStemming_FindsVariants() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Running helps with thinking clearly"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        logger.step(1, "Searching 'run' should find 'running'")
        try await assertSearchCount("run", expectedQuotes: 1)

        logger.step(2, "Searching 'runs' should find 'running'")
        try await assertSearchCount("runs", expectedQuotes: 1)

        logger.step(3, "Searching 'think' should find 'thinking'")
        try await assertSearchCount("think", expectedQuotes: 1)

        logger.success("Porter stemming works")
    }

    func testSearch_Stemming_PluralForms() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Building good habits takes time"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        // "habit" should find "habits"
        let results = try await search("habit")
        XCTAssertEqual(results.quotes.count, 1)

        logger.success("Plural form stemming works")
    }

    // MARK: - Scope Tests

    func testSearch_ScopeQuotes_OnlyQuotes() async throws {
        let book = TestFixtures.book { b in
            b.title = "The Art of Happiness"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Joy comes from within"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("happiness", scope: .quotes)

        // Only quotes should be searched, not book title
        XCTAssertEqual(results.books.count, 0)

        logger.success("Quote scope excludes books")
    }

    func testSearch_ScopeBooks_OnlyBooks() async throws {
        let book = TestFixtures.book { b in
            b.title = "The Art of Happiness"
        }
        let quote = TestFixtures.quote { q in
            q.text = "Happiness is a choice we make daily"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("happiness", scope: .books)

        // Only books should be searched
        XCTAssertEqual(results.quotes.count, 0)
        XCTAssertEqual(results.books.count, 1)

        logger.success("Book scope excludes quotes")
    }

    func testSearch_ScopeAll_BothResults() async throws {
        let book = TestFixtures.book { b in
            b.title = "Wisdom from the Masters"
        }
        let quote = TestFixtures.quote { q in
            q.text = "True wisdom comes from experience"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("wisdom", scope: .all)

        XCTAssertEqual(results.quotes.count, 1)
        XCTAssertEqual(results.books.count, 1)

        logger.success("All scope returns both")
    }

    // MARK: - Snippet Tests

    func testSearch_Snippet_ContainsHighlightMarkers() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "The path to success requires daily practice of good habits"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("success")
        let snippet = results.quotes.first?.snippet ?? ""

        XCTAssertTrue(snippet.contains("<mark>"))
        XCTAssertTrue(snippet.contains("</mark>"))

        logger.success("Snippets contain highlight markers")
    }

    func testSearchQuoteResult_PlainText_NoTags() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "The path to success requires practice"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("success")
        guard let result = results.quotes.first else {
            XCTFail("Expected at least one result")
            return
        }

        let plainText = result.plainText
        XCTAssertFalse(plainText.contains("<mark>"))
        XCTAssertFalse(plainText.contains("</mark>"))

        logger.success("Plain text has no HTML tags")
    }

    // MARK: - Edge Cases

    func testSearch_EmptyQuery_ReturnsEmpty() async throws {
        let results = try await search("")
        XCTAssertTrue(results.isEmpty)

        logger.success("Empty query returns empty results")
    }

    func testSearch_WhitespaceOnlyQuery_ReturnsEmpty() async throws {
        let results = try await search("   ")
        XCTAssertTrue(results.isEmpty)

        logger.success("Whitespace-only query returns empty results")
    }

    func testSearch_SpecialCharacters_Handled() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "What's the point? It's all about balance!"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        // Apostrophes and punctuation shouldn't break search
        let results = try await search("balance")
        XCTAssertFalse(results.isEmpty)

        logger.success("Special characters handled")
    }

    func testSearch_NoResults_ReturnsEmpty() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "A simple quote about life"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        let results = try await search("xyznonexistent")
        XCTAssertTrue(results.isEmpty)

        logger.success("Non-matching query returns empty")
    }

    func testSearch_CaseInsensitive() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "SUCCESS is earned through hard work"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        // Search lowercase
        let lowercaseResults = try await search("success")
        XCTAssertEqual(lowercaseResults.quotes.count, 1)

        // Search uppercase
        let uppercaseResults = try await search("SUCCESS")
        XCTAssertEqual(uppercaseResults.quotes.count, 1)

        logger.success("Search is case-insensitive")
    }

    // MARK: - Index Maintenance Tests

    func testRemoveQuote_RemovesFromIndex() async throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { q in
            q.text = "Unique searchable content"
            q.book = book
        }

        try insertBook(book)
        modelContext.insert(quote)
        try modelContext.save()
        try await indexBook(book)

        // Verify it's indexed
        try await assertSearchCount("unique", expectedQuotes: 1)

        // Remove from index
        try await searchDatabase.removeQuote(id: quote.id)

        // Verify it's gone
        try await assertSearchCount("unique", expectedQuotes: 0)

        logger.success("Quote removal from index works")
    }

    func testRemoveBook_RemovesFromIndex() async throws {
        let book = TestFixtures.book { b in
            b.title = "Unique Book Title"
        }

        try insertBook(book)
        try await indexBook(book)

        // Verify it's indexed
        try await assertSearchCount("Unique", expectedBooks: 1)

        // Remove from index
        try await searchDatabase.removeBook(id: book.id)

        // Verify it's gone
        try await assertSearchCount("Unique", expectedBooks: 0)

        logger.success("Book removal from index works")
    }

    func testRebuildIndex_ReindexesAll() async throws {
        let book1 = TestFixtures.book { b in
            b.title = "First Book"
        }
        let book2 = TestFixtures.book { b in
            b.title = "Second Book"
        }

        try insertBooks([book1, book2])
        try await rebuildIndex(books: [book1, book2])

        try await assertIndexCounts(quotes: 0, books: 2)

        logger.success("Rebuild index works")
    }

    // MARK: - Index Statistics Tests

    func testIndexStatistics_QuotesCount() async throws {
        let book = TestFixtures.book()
        try insertBook(book)

        for i in 1...5 {
            let quote = TestFixtures.quote { q in
                q.text = "Quote number \(i)"
                q.book = book
            }
            modelContext.insert(quote)
        }
        try modelContext.save()
        try await indexBook(book)

        let count = try await indexedQuotesCount()
        XCTAssertEqual(count, 5)

        logger.success("Quote count statistics work")
    }

    func testIndexStatistics_BooksCount() async throws {
        for i in 1...3 {
            let book = TestFixtures.book { b in
                b.title = "Book \(i)"
            }
            try insertBook(book)
            try await indexBook(book)
        }

        let count = try await indexedBooksCount()
        XCTAssertEqual(count, 3)

        logger.success("Book count statistics work")
    }

    // MARK: - Multiple Books/Quotes Tests

    func testSearch_MultipleBooks_FindsCorrectOne() async throws {
        let book1 = TestFixtures.book { b in
            b.title = "Python Programming"
            b.author = "John Developer"
        }
        let book2 = TestFixtures.book { b in
            b.title = "Swift Mastery"
            b.author = "Jane Coder"
        }

        try insertBooks([book1, book2])
        try await indexBooks([book1, book2])

        let pythonResults = try await search("Python", scope: .books)
        XCTAssertEqual(pythonResults.books.count, 1)
        XCTAssertEqual(pythonResults.books.first?.bookId, book1.id)

        let swiftResults = try await search("Swift", scope: .books)
        XCTAssertEqual(swiftResults.books.count, 1)
        XCTAssertEqual(swiftResults.books.first?.bookId, book2.id)

        logger.success("Multiple books search works")
    }

    func testSearch_QuotesAcrossBooks() async throws {
        let book1 = TestFixtures.book { b in b.title = "Book One" }
        let book2 = TestFixtures.book { b in b.title = "Book Two" }

        let quote1 = TestFixtures.quote { q in
            q.text = "Success comes from persistence"
            q.book = book1
        }
        let quote2 = TestFixtures.quote { q in
            q.text = "Success is a journey"
            q.book = book2
        }

        try insertBooks([book1, book2])
        modelContext.insert(quote1)
        modelContext.insert(quote2)
        try modelContext.save()
        try await indexBooks([book1, book2])

        let results = try await search("success")
        XCTAssertEqual(results.quotes.count, 2)

        logger.success("Search finds quotes across books")
    }
}
