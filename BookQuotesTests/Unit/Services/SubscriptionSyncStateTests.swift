import XCTest

@testable import BookQuotes

final class SubscriptionSyncStateTests: XCTestCase {
    func testMapsActiveResponseWithExpirationAndProductID() throws {
        let data = Data(
            """
            {
              "status": "active",
              "rawStatus": "SUBSCRIBED",
              "expiresAt": "2026-07-15T10:30:00Z",
              "productId": "com.bookquotes.yearly"
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(SubscriptionSyncResponse.self, from: data)
        let state = SubscriptionSyncState(response: response)

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.expiresAt, ISO8601DateFormatter().date(from: "2026-07-15T10:30:00Z"))
        XCTAssertEqual(state.productID, "com.bookquotes.yearly")
    }

    func testMapsCancelledBackendStatus() throws {
        let response = SubscriptionSyncResponse(
            status: "canceled",
            rawStatus: "AUTO_RENEW_DISABLED",
            expiresAt: nil,
            productId: "com.bookquotes.monthly"
        )

        let state = SubscriptionSyncState(response: response)

        XCTAssertEqual(state.status, .cancelled)
        XCTAssertNil(state.expiresAt)
        XCTAssertEqual(state.productID, "com.bookquotes.monthly")
    }

    func testUnknownStatusFallsBackToNone() {
        let response = SubscriptionSyncResponse(
            status: "billing_retry",
            rawStatus: "BILLING_RETRY",
            expiresAt: "not-a-date",
            productId: nil
        )

        let state = SubscriptionSyncState(response: response)

        XCTAssertEqual(state.status, .none)
        XCTAssertNil(state.expiresAt)
        XCTAssertNil(state.productID)
    }
}
