import Foundation

enum SubscriptionEntitlementReconciliationStatus: Equatable {
    case notStarted
    case synchronizing
    case confirmed
    case retryRequired

    var requiresUserAction: Bool {
        self == .retryRequired
    }

    var retryMessage: String {
        "Your purchase is confirmed by the App Store, but account verification is taking longer than expected. Keep this screen open and try Restore Purchases again."
    }
}

struct SubscriptionSyncResponse: Decodable, Equatable {
    let status: String
    let rawStatus: String
    let expiresAt: String?
    let productId: String?
}

struct SubscriptionSyncState: Equatable {
    let status: SubscriptionStatus
    let expiresAt: Date?
    let productID: String?

    init(
        response: SubscriptionSyncResponse,
        formatter: ISO8601DateFormatter = ISO8601DateFormatter()
    ) {
        status = SubscriptionStatus(rawValue: response.status) ?? .none
        expiresAt = response.expiresAt.flatMap { formatter.date(from: $0) }
        productID = response.productId
    }
}
