import Foundation

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
