import XCTest

@testable import BookQuotes

// MARK: - ISBNValidatorTests

final class ISBNValidatorTests: XCTestCase {

    func testValidateISBN10() {
        let result = ISBNValidator.validate("0306406152")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedISBN, "0306406152")
    }

    func testValidateISBN10WithXCheckDigit() {
        let result = ISBNValidator.validate("048665088X")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedISBN, "048665088X")
    }

    func testValidateISBN13() {
        let result = ISBNValidator.validate("9780306406157")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedISBN, "9780306406157")
    }

    func testValidateRejectsInvalidLength() {
        let result = ISBNValidator.validate("1234")
        XCTAssertFalse(result.isValid)
    }

    func testValidateRejectsBadChecksum() {
        let result = ISBNValidator.validate("0306406153")
        XCTAssertFalse(result.isValid)
    }

    func testToISBN13FromISBN10() {
        let converted = ISBNValidator.toISBN13("0-306-40615-2")
        XCTAssertEqual(converted, "9780306406157")
    }

    func testToISBN10FromISBN13() {
        let converted = ISBNValidator.toISBN10("9780306406157")
        XCTAssertEqual(converted, "0306406152")
    }

    func testIsbnFromBarcode() {
        let result = ISBNValidator.isbnFromBarcode("9780306406157")
        XCTAssertEqual(result, "9780306406157")

        let invalid = ISBNValidator.isbnFromBarcode("0123456789012")
        XCTAssertNil(invalid)
    }

    func testFormat() {
        XCTAssertEqual(ISBNValidator.format("0306406152"), "0-306-40615-2")
        XCTAssertEqual(ISBNValidator.format("9780306406157"), "978-0-306-40615-7")
        XCTAssertEqual(ISBNValidator.format("123"), "123")
    }
}
