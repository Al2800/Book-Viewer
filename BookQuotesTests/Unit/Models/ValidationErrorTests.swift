import XCTest

@testable import BookQuotes

// MARK: - ValidationErrorTests

final class ValidationErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(ValidationError.emptyTitle.errorDescription, "Book title cannot be empty")
        XCTAssertEqual(ValidationError.emptyAuthor.errorDescription, "Author name cannot be empty")
        XCTAssertEqual(ValidationError.emptyQuote.errorDescription, "Quote text cannot be empty")
        XCTAssertEqual(ValidationError.quoteTooShort.errorDescription, "Quote must be at least 10 characters")
        XCTAssertEqual(ValidationError.invalidRating.errorDescription, "Rating must be between 1 and 5")
    }
}
