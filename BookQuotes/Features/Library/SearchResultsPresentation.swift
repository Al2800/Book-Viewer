import Foundation

struct SearchResultsPresentation: Equatable {
    let scope: SearchScope
    let bookCount: Int
    let quoteCount: Int

    var totalCount: Int {
        bookCount + quoteCount
    }

    var showsBooks: Bool {
        bookCount > 0 && (scope == .all || scope == .books)
    }

    var showsQuotes: Bool {
        quoteCount > 0 && (scope == .all || scope == .quotes)
    }

    func bookAnimationDelay(index: Int) -> Double {
        Double(min(index, 8)) * 0.04
    }

    func quoteAnimationDelay(index: Int) -> Double {
        Double(min(bookCount + index, 12)) * 0.04
    }

    static func shouldResetResultsAnimation(oldCount: Int, newCount: Int) -> Bool {
        oldCount == 0 && newCount > 0
    }

    static func shouldFetchDidYouMean(
        resultCount: Int,
        searchText: String,
        isSearching: Bool
    ) -> Bool {
        resultCount == 0 && !searchText.isEmpty && !isSearching
    }
}
