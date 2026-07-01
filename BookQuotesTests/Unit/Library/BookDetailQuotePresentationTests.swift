import XCTest

@testable import BookQuotes

final class BookDetailQuotePresentationTests: XCTestCase {
    func testVisibleQuotesFilterByMarkingAndSortNewestFirst() {
        let olderUnderline = quote(markingType: .underline, captureDate: date(1), text: "older")
        let newerUnderline = quote(markingType: .underline, captureDate: date(3), text: "newer")
        let highlight = quote(markingType: .highlight, captureDate: date(2), text: "highlight")

        let presentation = BookDetailQuotePresentation(
            quotes: [olderUnderline, newerUnderline, highlight]
        )

        let visible = presentation.visibleQuotes(
            filter: .underline,
            sortOrder: .dateAdded
        )

        XCTAssertEqual(visible.map(\.text), ["newer", "older"])
    }

    func testVisibleQuotesSortByPageNumberTreatingMissingPagesAsZero() {
        let page10 = quote(pageNumber: 10, text: "page 10")
        let missingPage = quote(pageNumber: nil, text: "missing")
        let page3 = quote(pageNumber: 3, text: "page 3")

        let presentation = BookDetailQuotePresentation(
            quotes: [page10, missingPage, page3]
        )

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .pageNumber
        )

        XCTAssertEqual(visible.map(\.text), ["missing", "page 3", "page 10"])
    }

    func testVisibleQuotesSortByMarkingRawValue() {
        let underline = quote(markingType: .underline, text: "underline")
        let bracket = quote(markingType: .bracket, text: "bracket")
        let highlight = quote(markingType: .highlight, text: "highlight")

        let presentation = BookDetailQuotePresentation(
            quotes: [underline, bracket, highlight]
        )

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .markingType
        )

        XCTAssertEqual(visible.map(\.text), ["bracket", "highlight", "underline"])
    }

    func testVisibleQuotesSortFavoritesBeforeNonFavorites() {
        let firstFavorite = quote(text: "favorite 1", isFavorite: true)
        let nonFavorite = quote(text: "not favorite", isFavorite: false)
        let secondFavorite = quote(text: "favorite 2", isFavorite: true)

        let presentation = BookDetailQuotePresentation(
            quotes: [nonFavorite, firstFavorite, secondFavorite]
        )

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .favorite
        )

        XCTAssertEqual(visible.prefix(2).map(\.isFavorite), [true, true])
        XCTAssertFalse(visible.last?.isFavorite ?? true)
    }

    func testUniquePageCountAndMarkingTypesIgnoreDuplicates() {
        let presentation = BookDetailQuotePresentation(
            quotes: [
                quote(pageNumber: 12, markingType: .underline),
                quote(pageNumber: 12, markingType: .underline),
                quote(pageNumber: nil, markingType: .highlight),
                quote(pageNumber: 5, markingType: .bracket)
            ]
        )

        XCTAssertEqual(presentation.uniquePageCount, 2)
        XCTAssertEqual(presentation.markingTypes, [.bracket, .highlight, .underline])
    }

    private func quote(
        pageNumber: Int? = nil,
        markingType: MarkingType = .underline,
        captureDate: Date = Date(),
        text: String = UUID().uuidString,
        isFavorite: Bool = false
    ) -> Quote {
        let quote = Quote(text: text, markingType: markingType)
        quote.pageNumber = pageNumber
        quote.captureDate = captureDate
        quote.isFavorite = isFavorite
        return quote
    }

    private func date(_ day: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(day * 86_400))
    }
}
