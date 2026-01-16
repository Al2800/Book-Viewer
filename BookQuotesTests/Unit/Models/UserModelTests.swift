import XCTest

@testable import BookQuotes

// MARK: - UserModelTests

final class UserModelTests: XCTestCase {

    func testDisplayNameOrEmail() {
        let userWithName = User(id: "1", email: "test@example.com", displayName: "Ada", subscriptionStatus: .none, subscriptionExpiresAt: nil, sessionToken: nil)
        XCTAssertEqual(userWithName.displayNameOrEmail, "Ada")

        let userWithEmail = User(id: "2", email: "test@example.com", displayName: nil, subscriptionStatus: .none, subscriptionExpiresAt: nil, sessionToken: nil)
        XCTAssertEqual(userWithEmail.displayNameOrEmail, "test")

        let userNoInfo = User(id: "3", email: nil, displayName: nil, subscriptionStatus: .none, subscriptionExpiresAt: nil, sessionToken: nil)
        XCTAssertEqual(userNoInfo.displayNameOrEmail, "User")
    }

    func testHasActiveSubscription() {
        let activeUser = User(id: "1", email: nil, displayName: nil, subscriptionStatus: .active, subscriptionExpiresAt: nil, sessionToken: nil)
        XCTAssertTrue(activeUser.hasActiveSubscription)

        let expiredUser = User(id: "2", email: nil, displayName: nil, subscriptionStatus: .expired, subscriptionExpiresAt: nil, sessionToken: nil)
        XCTAssertFalse(expiredUser.hasActiveSubscription)

        let trialExpired = User(id: "3", email: nil, displayName: nil, subscriptionStatus: .trial, subscriptionExpiresAt: Date().addingTimeInterval(-10), sessionToken: nil)
        XCTAssertFalse(trialExpired.hasActiveSubscription)
    }

    func testSubscriptionStatusDisplayAndAccess() {
        XCTAssertEqual(SubscriptionStatus.active.displayName, "Active")
        XCTAssertTrue(SubscriptionStatus.active.hasAccess)
        XCTAssertFalse(SubscriptionStatus.cancelled.hasAccess)
    }
}
