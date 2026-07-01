import Foundation

enum SubscriptionProductID: String, CaseIterable {
    case monthly = "com.bookquotes.monthly"
    case yearly = "com.bookquotes.yearly"

    static var allRawValues: [String] {
        allCases.map(\.rawValue)
    }

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
