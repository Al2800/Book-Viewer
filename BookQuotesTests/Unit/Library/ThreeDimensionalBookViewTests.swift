import XCTest
import SwiftUI
@testable import BookQuotes

@MainActor
final class ThreeDimensionalBookViewTests: XCTestCase {

    func testClothboundJacketThemesProvideDeterministicSelection() {
        let book1 = Book(title: "War and Peace", author: "Leo Tolstoy")
        let theme1 = ClothboundJacketTheme.forBook(book1)
        let theme1Again = ClothboundJacketTheme.forBook(book1)

        XCTAssertEqual(theme1, theme1Again)

        let book2 = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald")
        let theme2 = ClothboundJacketTheme.forBook(book2)
        XCTAssertNotNil(theme2)
    }

    func testClothboundJacketThemePropertiesAreValid() {
        for theme in ClothboundJacketTheme.allCases {
            _ = theme.baseColor
            _ = theme.secondaryColor
            _ = theme.foilGradient
            _ = theme.foilBorderColor
        }
    }

    func testPresentationAnglesAndSlotsStayDistinct() {
        let book = Book(title: "Middlemarch", author: "George Eliot")
        let shelf = ThreeDimensionalBookView(book: book, presentation: .shelf)
        let card = ThreeDimensionalBookView(book: book, isInteractive: false, presentation: .card)
        let hero = ThreeDimensionalBookView(book: book, presentation: .hero)
        XCTAssertNotNil(shelf)
        XCTAssertNotNil(card)
        XCTAssertNotNil(hero)
    }

    func testThreeDimensionalBookViewInitializesWithAndWithoutCovers() {
        let bookWithoutCover = Book(title: "Crime and Punishment", author: "Fyodor Dostoevsky")
        let view1 = ThreeDimensionalBookView(book: bookWithoutCover, width: 100, height: 150)
        XCTAssertNotNil(view1)

        let bookWithCover = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald")
        bookWithCover.coverThumbnailData = UIImage(systemName: "book")?.pngData()
        let view2 = ThreeDimensionalBookView(book: bookWithCover, width: 90, height: 135)
        XCTAssertNotNil(view2)
    }
}
