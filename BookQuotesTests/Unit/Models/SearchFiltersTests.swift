import XCTest
import SwiftData

@testable import BookQuotes

// MARK: - SearchFiltersTests

@MainActor
final class SearchFiltersTests: SwiftDataTestCase {

    func testActiveFilterCountAndSelections() {
        var filters = SearchFilters()
        XCTAssertFalse(filters.isActive)
        XCTAssertEqual(filters.activeFilterCount, 0)

        let bookId = UUID()
        filters.addBook(bookId)
        filters.toggleMarkingType("Underline")
        filters.favoritesOnly = true

        XCTAssertTrue(filters.isActive)
        XCTAssertEqual(filters.activeFilterCount, 3)
        XCTAssertEqual(filters.totalSelections, 3)
    }

    func testMatchesHonorsBookAndMarkingType() throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.markingType = .underline
        }

        var filters = SearchFilters()
        filters.addBook(book.id)
        filters.addMarkingType(quote.markingType.displayName)

        XCTAssertTrue(filters.matches(quote: quote, book: book))

        // Keep the marking filter active but make it a mismatch to ensure the marking-type filter is honored.
        filters.toggleMarkingType(quote.markingType.displayName) // remove Underline
        filters.addMarkingType(MarkingType.highlight.displayName)
        XCTAssertFalse(filters.matches(quote: quote, book: book))
    }

    func testMatchesHonorsFavoritesAndConfidence() throws {
        let book = TestFixtures.book()
        let quote = TestFixtures.quote { builder in
            builder.book = book
            builder.isFavorite = true
            builder.confidence = 0.6
        }

        var filters = SearchFilters()
        filters.favoritesOnly = true
        filters.minConfidence = 0.7

        XCTAssertFalse(filters.matches(quote: quote, book: book))

        filters.minConfidence = 0.5
        XCTAssertTrue(filters.matches(quote: quote, book: book))
    }
}
