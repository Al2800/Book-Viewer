import Foundation
import SwiftData

// MARK: - UITestDataSeeder

/// Seeds deterministic test data for UI tests.
///
/// This service creates known books and quotes that UI tests can assert against.
/// All test data uses deterministic UUIDs for idempotent seeding.
///
/// Usage:
/// ```swift
/// let seeder = UITestDataSeeder(modelContext: context)
/// await seeder.seedTestDataIfNeeded()
/// ```
@MainActor
final class UITestDataSeeder {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Deterministic UUIDs

    /// Known UUIDs for idempotent seeding
    private enum TestIDs {
        // Books
        static let atomicHabits = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        static let deepWork = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        static let thinkingFastSlow = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        static let testBook = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

        // Quotes
        static let quote1 = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        static let quote2 = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        static let quote3 = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        static let quote4 = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        static let quote5 = UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!
        static let quote6 = UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff")!
        static let quote7 = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        static let quote8 = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        static let quote9 = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        static let quote10 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Seeding

    /// Seed test data based on launch arguments.
    func seedTestDataIfNeeded() async throws {
        // Only seed in UI test mode
        guard UITestConfiguration.isUITesting else { return }

        // Empty library mode - delete all existing data
        if UITestConfiguration.shouldStartWithEmptyLibrary {
            try deleteAllData()
            return
        }

        // Seed library test data
        if UITestConfiguration.shouldPreloadLibraryTestData {
            try seedLibraryTestData()
        }

        // Seed search test data (includes library data plus search-specific tokens)
        if UITestConfiguration.shouldPreloadSearchTestData {
            try seedSearchTestData()
        }

        // Seed single test book
        if UITestConfiguration.shouldPreloadTestBook {
            try seedTestBook()
        }

        try modelContext.save()
    }

    // MARK: - Library Test Data

    /// Seeds 3 books with 6+ quotes for general library testing.
    private func seedLibraryTestData() throws {
        // Check if already seeded (idempotent)
        if bookExists(id: TestIDs.atomicHabits) { return }

        // Book 1: Atomic Habits
        let atomicHabits = createBook(
            id: TestIDs.atomicHabits,
            title: "Atomic Habits",
            author: "James Clear",
            subtitle: "An Easy & Proven Way to Build Good Habits",
            status: .currentlyReading
        )

        createQuote(
            id: TestIDs.quote1,
            text: "Every action you take is a vote for the type of person you wish to become.",
            book: atomicHabits,
            pageNumber: 38,
            markingType: .underline,
            isFavorite: true
        )

        createQuote(
            id: TestIDs.quote2,
            text: "You do not rise to the level of your goals. You fall to the level of your systems.",
            book: atomicHabits,
            pageNumber: 27,
            markingType: .doubleUnderline,
            marginNote: "Key insight!"
        )

        createQuote(
            id: TestIDs.quote3,
            text: "Habits are the compound interest of self-improvement.",
            book: atomicHabits,
            pageNumber: 16,
            markingType: .highlight
        )

        // Book 2: Deep Work
        let deepWork = createBook(
            id: TestIDs.deepWork,
            title: "Deep Work",
            author: "Cal Newport",
            subtitle: "Rules for Focused Success in a Distracted World",
            status: .finished
        )

        createQuote(
            id: TestIDs.quote4,
            text: "Deep work is the ability to focus without distraction on a cognitively demanding task.",
            book: deepWork,
            pageNumber: 3,
            markingType: .underline
        )

        createQuote(
            id: TestIDs.quote5,
            text: "Clarity about what matters provides clarity about what does not.",
            book: deepWork,
            pageNumber: 62,
            markingType: .marginLine,
            isFavorite: true
        )

        // Book 3: Thinking, Fast and Slow
        let thinkingBook = createBook(
            id: TestIDs.thinkingFastSlow,
            title: "Thinking, Fast and Slow",
            author: "Daniel Kahneman",
            status: .wantToRead
        )

        createQuote(
            id: TestIDs.quote6,
            text: "Nothing in life is as important as you think it is while you are thinking about it.",
            book: thinkingBook,
            pageNumber: 402,
            markingType: .highlight
        )
    }

    // MARK: - Search Test Data

    /// Seeds data with specific tokens for search testing.
    private func seedSearchTestData() throws {
        // First seed the standard library data
        try seedLibraryTestData()

        // Check if search-specific data already seeded
        if quoteExists(id: TestIDs.quote7) { return }

        // Fetch existing books
        guard let atomicHabits = fetchBook(id: TestIDs.atomicHabits),
              let deepWork = fetchBook(id: TestIDs.deepWork) else {
            return
        }

        // Add quotes with specific search tokens

        // Token: "improvement" (for exact match testing)
        createQuote(
            id: TestIDs.quote7,
            text: "The process of improvement is not about adding something. It's about becoming less.",
            book: atomicHabits,
            pageNumber: 89,
            markingType: .bracket
        )

        // Token: "focus" (appears in multiple quotes)
        createQuote(
            id: TestIDs.quote8,
            text: "Focus is the ability to say no to every other option.",
            book: deepWork,
            pageNumber: 124,
            markingType: .underline
        )

        // Token: "mindfulness" (unique token for testing)
        createQuote(
            id: TestIDs.quote9,
            text: "Mindfulness is the practice of being present in each moment.",
            book: atomicHabits,
            pageNumber: 156,
            markingType: .marginNote,
            marginNote: "Practice daily"
        )

        // Low confidence quote for filter testing
        createQuote(
            id: TestIDs.quote10,
            text: "Partially readable passage about concentration and discipline.",
            book: deepWork,
            pageNumber: 201,
            markingType: .mixed,
            confidence: 0.45
        )
    }

    // MARK: - Single Test Book

    /// Seeds a single "Test Book" with known quotes for focused testing.
    private func seedTestBook() throws {
        // Check if already seeded
        if bookExists(id: TestIDs.testBook) { return }

        let testBook = createBook(
            id: TestIDs.testBook,
            title: "Test Book",
            author: "Test Author",
            subtitle: "A Book for Testing",
            status: .currentlyReading
        )

        createQuote(
            id: TestIDs.quote1,
            text: "This is the first test quote for automation testing purposes.",
            book: testBook,
            pageNumber: 1,
            markingType: .underline
        )

        createQuote(
            id: TestIDs.quote2,
            text: "The second test quote contains searchable keywords like automation and testing.",
            book: testBook,
            pageNumber: 2,
            markingType: .highlight,
            isFavorite: true
        )

        createQuote(
            id: TestIDs.quote3,
            text: "A third quote with a margin note for testing that feature.",
            book: testBook,
            pageNumber: 3,
            markingType: .marginNote,
            marginNote: "Remember this!"
        )
    }

    // MARK: - Helpers

    @discardableResult
    private func createBook(
        id: UUID,
        title: String,
        author: String,
        subtitle: String? = nil,
        status: ReadingStatus = .wantToRead
    ) -> Book {
        let book = Book(title: title, author: author, subtitle: subtitle)
        // Override the auto-generated UUID with our deterministic one
        book.id = id
        book.status = status
        modelContext.insert(book)
        return book
    }

    @discardableResult
    private func createQuote(
        id: UUID,
        text: String,
        book: Book,
        pageNumber: Int? = nil,
        markingType: MarkingType = .underline,
        marginNote: String? = nil,
        isFavorite: Bool = false,
        confidence: Double? = nil
    ) -> Quote {
        let quote = Quote(text: text, book: book, markingType: markingType)
        // Override the auto-generated UUID with our deterministic one
        quote.id = id
        quote.pageNumber = pageNumber
        quote.marginNote = marginNote
        quote.isFavorite = isFavorite
        quote.confidence = confidence ?? 0.95
        modelContext.insert(quote)
        return quote
    }

    private func bookExists(id: UUID) -> Bool {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.id == id }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    private func quoteExists(id: UUID) -> Bool {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { $0.id == id }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    private func fetchBook(id: UUID) -> Book? {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func deleteAllData() throws {
        try modelContext.delete(model: Quote.self)
        try modelContext.delete(model: Book.self)
        try modelContext.delete(model: Collection.self)
        try modelContext.delete(model: Tag.self)
        try modelContext.save()
    }
}

// MARK: - UITestDataSeeding Conformance

extension UITestDataSeeder: UITestDataSeeding {
    nonisolated func seedTestDataIfNeeded() async throws {
        try await MainActor.run {
            try self.seedTestDataIfNeeded()
        }
    }
}

// MARK: - Test Data Constants

/// Constants for UI test assertions.
/// These values match what's seeded by UITestDataSeeder.
enum UITestData {
    enum Books {
        static let atomicHabitsTitle = "Atomic Habits"
        static let atomicHabitsAuthor = "James Clear"
        static let deepWorkTitle = "Deep Work"
        static let deepWorkAuthor = "Cal Newport"
        static let thinkingTitle = "Thinking, Fast and Slow"
        static let thinkingAuthor = "Daniel Kahneman"
        static let testBookTitle = "Test Book"
        static let testBookAuthor = "Test Author"
    }

    enum Quotes {
        static let voteQuote = "Every action you take is a vote for the type of person you wish to become."
        static let systemsQuote = "You do not rise to the level of your goals. You fall to the level of your systems."
        static let compoundQuote = "Habits are the compound interest of self-improvement."
        static let deepWorkQuote = "Deep work is the ability to focus without distraction"
        static let clarityQuote = "Clarity about what matters provides clarity about what does not."
    }

    enum SearchTokens {
        static let improvement = "improvement"
        static let focus = "focus"
        static let mindfulness = "mindfulness"
        static let habits = "habits"
        static let automation = "automation"
    }

    enum Counts {
        static let libraryBooks = 3
        static let libraryQuotes = 6
        static let searchQuotes = 10
        static let testBookQuotes = 3
    }
}
