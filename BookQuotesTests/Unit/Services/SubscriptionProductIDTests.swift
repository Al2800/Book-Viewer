import XCTest

@testable import BookQuotes

final class SubscriptionProductIDTests: XCTestCase {
    func testProductIdentifiersMatchAppStoreConnectProducts() {
        XCTAssertEqual(SubscriptionProductID.monthly.rawValue, "com.bookquotes.monthly")
        XCTAssertEqual(SubscriptionProductID.yearly.rawValue, "com.bookquotes.yearly")
    }

    func testProductIdentifiersStayInDisplayOrder() {
        XCTAssertEqual(SubscriptionProductID.allCases, [.monthly, .yearly])
        XCTAssertEqual(SubscriptionProductID.allRawValues, [
            "com.bookquotes.monthly",
            "com.bookquotes.yearly"
        ])
    }

    func testDisplayNamesMatchPaywallCopy() {
        XCTAssertEqual(SubscriptionProductID.monthly.displayName, "Monthly")
        XCTAssertEqual(SubscriptionProductID.yearly.displayName, "Yearly")
    }
}
