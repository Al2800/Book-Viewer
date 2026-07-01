import XCTest

@testable import BookQuotes

final class SubscriptionAccountTokenTests: XCTestCase {
    func testTokenIsStableForUserID() {
        let token = SubscriptionAccountToken.token(for: "reader-1")

        XCTAssertEqual(token.uuidString.lowercased(), "bf66392e-c65d-53e4-a467-eef774ead731")
    }

    func testDifferentUserIDsGetDifferentTokens() {
        let firstToken = SubscriptionAccountToken.token(for: "reader-1")
        let secondToken = SubscriptionAccountToken.token(for: "reader-2")

        XCTAssertNotEqual(firstToken, secondToken)
        XCTAssertEqual(secondToken.uuidString.lowercased(), "46b9ff17-a41b-5121-b75a-c4b0d7f221d7")
    }

    func testTokenUsesVersionFiveAndRfc4122VariantBits() {
        let token = SubscriptionAccountToken.token(for: "reader-1")
        let bytes = withUnsafeBytes(of: token.uuid) { Array($0) }

        XCTAssertEqual(bytes[6] >> 4, 0x5)
        XCTAssertEqual(bytes[8] >> 6, 0x2)
    }
}
