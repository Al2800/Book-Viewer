import XCTest

@testable import BookQuotes

final class BookISBNConfirmationValidationTests: XCTestCase {
    func testValidatesNonBlankTitleAndAuthor() {
        let validation = BookISBNConfirmationValidation(
            title: "The Pragmatic Programmer",
            author: "David Thomas"
        )

        XCTAssertTrue(validation.isTitleValid)
        XCTAssertTrue(validation.isAuthorValid)
        XCTAssertTrue(validation.isValid)
    }

    func testRejectsBlankTitle() {
        let validation = BookISBNConfirmationValidation(
            title: "   ",
            author: "David Thomas"
        )

        XCTAssertFalse(validation.isTitleValid)
        XCTAssertTrue(validation.isAuthorValid)
        XCTAssertFalse(validation.isValid)
    }

    func testRejectsBlankAuthor() {
        let validation = BookISBNConfirmationValidation(
            title: "The Pragmatic Programmer",
            author: "   "
        )

        XCTAssertTrue(validation.isTitleValid)
        XCTAssertFalse(validation.isAuthorValid)
        XCTAssertFalse(validation.isValid)
    }
}
