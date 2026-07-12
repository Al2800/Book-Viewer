import Foundation
import OSLog
import StoreKit

// MARK: - SubscriptionService

/// Service handling StoreKit 2 subscription management.
@MainActor
@Observable
final class SubscriptionService {

    private static let logger = Logger(subsystem: "com.acampbell.bookquotes", category: "Subscription")

    // MARK: - Properties

    /// Available subscription products
    private(set) var products: [Product] = []

    /// Currently purchased subscription
    private(set) var purchasedSubscription: Product?

    /// Purchased product identifier retained even before product metadata is loaded.
    private(set) var purchasedProductID: String?

    /// Current subscription status
    private(set) var subscriptionStatus: Product.SubscriptionInfo.Status?

    /// Expiration date for the current entitlement.
    private(set) var currentExpirationDate: Date?

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

        if purchasedProductID != nil {
            if let currentExpirationDate {
                return currentExpirationDate > Date()
            }
            return true
        }

        return false
    }

    /// Whether user is in free trial
    var isInTrial: Bool {
        guard let status = subscriptionStatus else { return false }
        guard case .verified(let renewalInfo) = status.renewalInfo else {
            return false
        }
        return status.state == .subscribed && renewalInfo.offerType == .introductory
    }

    /// Monthly product if available
    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.monthly.rawValue }
    }

    /// Yearly product if available
    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProductID.yearly.rawValue }
    }

    // MARK: - Initialization

    init(authService: AuthService) {
        self.authService = authService
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
            products = try await Product.products(for: Set(SubscriptionProductID.allRawValues))
                .sorted { $0.price < $1.price }

            // Also update subscription status
            await updateSubscriptionStatus()
        } catch {
            lastError = .productLoadFailed(error)
            Self.logger.error("Failed to load products: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Purchase

    /// Purchase a subscription product
    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        lastError = nil

        let result = try await product.purchase(options: purchaseOptions())

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()

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
        purchasedProductID = nil
        subscriptionStatus = nil
        currentExpirationDate = nil
        var latestTransaction: Transaction?

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    if shouldReplaceCurrentEntitlement(with: transaction, current: latestTransaction) {
                        latestTransaction = transaction
                    }
                }
            }
        }

        if let latestTransaction {
            purchasedProductID = latestTransaction.productID
            currentExpirationDate = latestTransaction.expirationDate

            purchasedSubscription = products.first { $0.id == latestTransaction.productID }

            if let product = purchasedSubscription,
               let subscription = product.subscription {
                let statuses = try? await subscription.status
                subscriptionStatus = statuses?.first { $0.state != .expired && $0.state != .revoked }
            }

            await refreshSubscriptionWithServer(transaction: latestTransaction)
        } else {
            await refreshSubscriptionWithServer(transaction: nil)
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

    private func shouldReplaceCurrentEntitlement(with candidate: Transaction, current: Transaction?) -> Bool {
        guard let current else { return true }

        let candidateExpiry = candidate.expirationDate ?? candidate.purchaseDate
        let currentExpiry = current.expirationDate ?? current.purchaseDate
        if candidateExpiry != currentExpiry {
            return candidateExpiry > currentExpiry
        }

        return candidate.purchaseDate > current.purchaseDate
    }

    private func purchaseOptions() -> Set<Product.PurchaseOption> {
        guard let userID = authService.currentUser?.id else {
            return []
        }

        return [.appAccountToken(SubscriptionAccountToken.token(for: userID))]
    }

    /// Ask the backend to verify subscription status against the App Store Server API.
    private func refreshSubscriptionWithServer(transaction: Transaction?) async {
        guard let token = authService.getSessionToken() else { return }

        let serverURL = AuthService.proxyBaseURL.appendingPathComponent("api/subscription/sync")
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]
        if let transaction {
            body["transactionId"] = String(transaction.id)
            body["originalTransactionId"] = transaction.originalID
            body["environment"] = transaction.environment.rawValue
            if let appAccountToken = transaction.appAccountToken {
                body["appAccountToken"] = appAccountToken.uuidString.lowercased()
            }
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                authService.applyRefreshedSessionToken(from: httpResponse)
                if httpResponse.statusCode != 200 {
                    Self.logger.error("Backend verification failed: \(httpResponse.statusCode)")
                    return
                }
            }

            let syncResponse = try JSONDecoder().decode(SubscriptionSyncResponse.self, from: data)
            let syncState = SubscriptionSyncState(response: syncResponse)

            authService.updateSubscriptionState(status: syncState.status, expiresAt: syncState.expiresAt)
            currentExpirationDate = syncState.expiresAt

            if purchasedProductID == nil {
                purchasedProductID = syncState.productID ?? transaction?.productID
            }
        } catch {
            Self.logger.error("Backend verification error: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Manage Subscription

    /// Open system subscription management
    func manageSubscription() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                Self.logger.error("Failed to show subscription management: \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// Request refund for a transaction
    func requestRefund(for transactionId: UInt64) async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                _ = try await Transaction.beginRefundRequest(for: transactionId, in: windowScene)
            } catch {
                Self.logger.error("Failed to begin refund request: \(String(describing: error), privacy: .public)")
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
        return monthlyPrice.formatted(.currency(code: priceFormatStyle.currencyCode))
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

        let savingsValue = NSDecimalNumber(decimal: savings).doubleValue
        return Int(savingsValue.rounded())
    }
}
