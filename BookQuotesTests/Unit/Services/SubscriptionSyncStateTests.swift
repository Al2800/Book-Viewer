import XCTest

@testable import BookQuotes

final class SubscriptionSyncStateTests: XCTestCase {

    func testRestoreUsesExistingActiveEntitlementBeforeRequestingAppStoreSync() {
        XCTAssertFalse(
            SubscriptionRestorePolicy.shouldRequestAppStoreSync(hasActiveEntitlement: true)
        )
        XCTAssertTrue(
            SubscriptionRestorePolicy.shouldRequestAppStoreSync(hasActiveEntitlement: false)
        )
    }

    func testReconciliationStatusRequiresUserActionOnlyAfterSyncFailure() {
        XCTAssertFalse(SubscriptionEntitlementReconciliationStatus.notStarted.requiresUserAction)
        XCTAssertFalse(SubscriptionEntitlementReconciliationStatus.synchronizing.requiresUserAction)
        XCTAssertFalse(SubscriptionEntitlementReconciliationStatus.confirmed.requiresUserAction)
        XCTAssertTrue(SubscriptionEntitlementReconciliationStatus.retryRequired.requiresUserAction)
    }

    func testReconciliationRetryMessageExplainsThePurchaseIsStillOwned() {
        let message = SubscriptionEntitlementReconciliationStatus.retryRequired.retryMessage

        XCTAssertTrue(message.contains("purchase is confirmed by the App Store"))
        XCTAssertTrue(message.contains("Restore Purchases"))
    }

    func testReconciliationPendingErrorPreservesTheRecoveryGuidance() {
        XCTAssertEqual(
            SubscriptionError.entitlementReconciliationPending.errorDescription,
            SubscriptionEntitlementReconciliationStatus.retryRequired.retryMessage
        )
    }

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
