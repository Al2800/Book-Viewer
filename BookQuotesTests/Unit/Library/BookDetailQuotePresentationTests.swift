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

    func testVisibleQuotesSearchMatchesTextCaseInsensitively() {
        let matching = quote(text: "The pleasure of finding things out")
        let other = quote(text: "Something else entirely")

        let presentation = BookDetailQuotePresentation(quotes: [matching, other])

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .dateAdded,
            searchText: "PLEASURE"
        )

        XCTAssertEqual(visible.map(\.text), ["The pleasure of finding things out"])
    }

    func testVisibleQuotesSearchMatchesMarginAndPersonalNotes() {
        let marginMatch = quote(text: "Quote A")
        marginMatch.marginNote = "Remember this for the essay"
        let personalMatch = quote(text: "Quote B")
        personalMatch.personalNote = "Great essay material"
        let noMatch = quote(text: "Quote C")

        let presentation = BookDetailQuotePresentation(
            quotes: [marginMatch, personalMatch, noMatch]
        )

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .dateAdded,
            searchText: "essay"
        )

        XCTAssertEqual(Set(visible.map(\.text)), ["Quote A", "Quote B"])
    }

    func testVisibleQuotesSearchComposesWithMarkingFilter() {
        let underlineMatch = quote(markingType: .underline, text: "habit stacking")
        let highlightMatch = quote(markingType: .highlight, text: "habit loops")

        let presentation = BookDetailQuotePresentation(
            quotes: [underlineMatch, highlightMatch]
        )

        let visible = presentation.visibleQuotes(
            filter: .underline,
            sortOrder: .dateAdded,
            searchText: "habit"
        )

        XCTAssertEqual(visible.map(\.text), ["habit stacking"])
    }

    func testVisibleQuotesSearchIgnoresDiacritics() {
        let accented = quote(text: "A quiet café on the corner")
        let other = quote(text: "Nothing to see here")

        let presentation = BookDetailQuotePresentation(quotes: [accented, other])

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .dateAdded,
            searchText: "cafe"
        )

        XCTAssertEqual(visible.map(\.text), ["A quiet café on the corner"])
    }

    func testVisibleQuotesBlankSearchTextIsIgnored() {
        let presentation = BookDetailQuotePresentation(
            quotes: [quote(text: "anything")]
        )

        let visible = presentation.visibleQuotes(
            filter: nil,
            sortOrder: .dateAdded,
            searchText: "   "
        )

        XCTAssertEqual(visible.count, 1)
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
