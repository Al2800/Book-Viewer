import Foundation
import StoreKit

// MARK: - SubscriptionService

/// Service handling StoreKit 2 subscription management.
@MainActor
@Observable
final class SubscriptionService {

    // MARK: - Product IDs

    /// Available subscription product identifiers
    enum ProductID: String, CaseIterable {
        case monthly = "com.bookquotes.monthly"
        case yearly = "com.bookquotes.yearly"

        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
    }

    // MARK: - Properties

    /// Available subscription products
    private(set) var products: [Product] = []

    /// Currently purchased subscription
    private(set) var purchasedSubscription: Product?

    /// Current subscription status
    private(set) var subscriptionStatus: Product.SubscriptionInfo.Status?

    /// Whether products are loading
    private(set) var isLoading = false

    /// Last error encountered
    private(set) var lastError: SubscriptionError?

    /// Auth service for syncing with backend
    private let authService: AuthService

    /// Transaction listener task
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Computed Properties

    /// Whether user has active subscription
    var hasActiveSubscription: Bool {
        if let status = subscriptionStatus {
            switch status.state {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                return true
            default:
                return false
            }
        }
        return purchasedSubscription != nil
    }

    /// Whether user is in free trial
    var isInTrial: Bool {
        guard let status = subscriptionStatus else { return false }
        return status.state == .subscribed &&
               status.renewalInfo?.offerType == .introductory
    }

    /// Monthly product if available
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthly.rawValue }
    }

    /// Yearly product if available
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearly.rawValue }
    }

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Setup

    /// Start listening for transaction updates
    func startListening() {
        updateListenerTask = Task(priority: .background) {
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
        }
    }

    // MARK: - Product Loading

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        do {
            let productIds = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: Set(productIds))
                .sorted { $0.price < $1.price }

            // Also update subscription status
            await updateSubscriptionStatus()
        } catch {
            lastError = .productLoadFailed(error)
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase a subscription product
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        lastError = nil

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()

            // Sync with backend
            await syncSubscriptionWithServer(transaction)

            return transaction

        case .pending:
            // Transaction is pending (e.g., Ask to Buy)
            return nil

        case .userCancelled:
            // User cancelled - not an error
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    func restorePurchases() async throws {
        lastError = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            lastError = .restoreFailed(error)
            throw error
        }
    }

    // MARK: - Status Updates

    /// Update subscription status from App Store
    func updateSubscriptionStatus() async {
        purchasedSubscription = nil
        subscriptionStatus = nil

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    // Find the product
                    purchasedSubscription = products.first { $0.id == transaction.productID }

                    // Get detailed subscription status
                    if let product = purchasedSubscription,
                       let subscription = product.subscription {
                        let statuses = try? await subscription.status
                        subscriptionStatus = statuses?.first { $0.state != .expired && $0.state != .revoked }
                    }

                    // Sync with backend
                    await syncSubscriptionWithServer(transaction)
                }
            }
        }
    }

    // MARK: - Transaction Handling

    /// Handle transaction updates from App Store
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }

        if transaction.productType == .autoRenewable {
            await updateSubscriptionStatus()
        }

        await transaction.finish()
    }

    /// Verify transaction signature
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw SubscriptionError.verificationFailed(error)
        }
    }

    // MARK: - Backend Sync

    /// Sync subscription status with backend server
    private func syncSubscriptionWithServer(_ transaction: Transaction) async {
        guard let token = authService.getSessionToken() else { return }

        // Create sync request
        var components = URLComponents()
        components.scheme = "https"
        components.host = "bookquotes-proxy.your-worker.workers.dev"
        components.path = "/api/subscription/sync"

        guard let serverURL = components.url else {
            print("Invalid subscription sync URL")
            return
        }
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "productId": transaction.productID,
            "transactionId": String(transaction.id),
            "originalTransactionId": transaction.originalID,
            "purchaseDate": ISO8601DateFormatter().string(from: transaction.purchaseDate),
            "expirationDate": transaction.expirationDate.map { ISO8601DateFormatter().string(from: $0) } as Any,
            "isUpgraded": transaction.isUpgraded,
            "environment": transaction.environment.rawValue
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                print("Backend sync failed: \(httpResponse.statusCode)")
            }
        } catch {
            print("Backend sync error: \(error)")
        }
    }

    // MARK: - Manage Subscription

    /// Open system subscription management
    func manageSubscription() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show subscription management: \(error)")
            }
        }
    }

    /// Request refund for a transaction
    func requestRefund(for transactionId: UInt64) async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await Transaction.beginRefundRequest(for: transactionId, in: windowScene)
            } catch {
                print("Failed to begin refund request: \(error)")
            }
        }
    }
}

// MARK: - SubscriptionError

/// Errors that can occur during subscription operations
enum SubscriptionError: LocalizedError {
    case productLoadFailed(Error)
    case verificationFailed(Error)
    case purchaseFailed(Error)
    case restoreFailed(Error)

    var errorDescription: String? {
        switch self {
        case .productLoadFailed(let error):
            return "Failed to load products: \(error.localizedDescription)"
        case .verificationFailed(let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    /// Formatted price string with period
    var priceWithPeriod: String {
        guard let subscription = subscription else {
            return displayPrice
        }

        let unit = subscription.subscriptionPeriod.unit
        switch unit {
        case .month:
            return "\(displayPrice)/month"
        case .year:
            return "\(displayPrice)/year"
        case .week:
            return "\(displayPrice)/week"
        case .day:
            return "\(displayPrice)/day"
        @unknown default:
            return displayPrice
        }
    }

    /// Whether this product offers a free trial
    var hasFreeTrial: Bool {
        subscription?.introductoryOffer?.paymentMode == .freeTrial
    }

    /// Free trial duration description
    var freeTrialDescription: String? {
        guard let offer = subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else {
            return nil
        }

        let period = offer.period
        let unit: String
        switch period.unit {
        case .day:
            unit = period.value == 1 ? "day" : "days"
        case .week:
            unit = period.value == 1 ? "week" : "weeks"
        case .month:
            unit = period.value == 1 ? "month" : "months"
        case .year:
            unit = period.value == 1 ? "year" : "years"
        @unknown default:
            unit = "days"
        }

        return "\(period.value) \(unit) free trial"
    }

    /// Monthly equivalent price for yearly subscriptions
    var monthlyEquivalent: String? {
        guard let subscription = subscription,
              subscription.subscriptionPeriod.unit == .year else {
            return nil
        }

        let monthlyPrice = price / 12
        return monthlyPrice.formatted(.currency(code: priceFormatStyle.currencyCode ?? "USD"))
    }

    /// Savings percentage compared to monthly
    func savingsPercentage(comparedTo monthly: Product) -> Int? {
        guard let yearlySubscription = subscription,
              let monthlySubscription = monthly.subscription,
              yearlySubscription.subscriptionPeriod.unit == .year,
              monthlySubscription.subscriptionPeriod.unit == .month else {
            return nil
        }

        let yearlyMonthlyPrice = price / 12
        let monthlyPrice = monthly.price
        let savings = (1 - (yearlyMonthlyPrice / monthlyPrice)) * 100

        return Int(savings.rounded())
    }
}
