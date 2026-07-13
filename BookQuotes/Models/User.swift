import Foundation

// MARK: - User

/// Represents an authenticated user in the app.
struct User: Codable, Equatable, Sendable {

    // MARK: - Properties

    /// Unique identifier from Apple Sign-In
    let id: String

    /// User's email (may be private relay if "Hide My Email" was used)
    let email: String?

    /// User's display name (only provided on first sign-in)
    let displayName: String?

    /// Current subscription status
    var subscriptionStatus: SubscriptionStatus

    /// When the subscription expires
    var subscriptionExpiresAt: Date?

    /// Session token for API requests
    var sessionToken: String?

    // MARK: - Computed Properties

    /// Whether the user has an active subscription or trial
    var hasActiveSubscription: Bool {
        switch subscriptionStatus {
        case .active, .trial:
            if let expiresAt = subscriptionExpiresAt {
                return expiresAt > Date()
            }
            return true
        case .none, .expired, .cancelled:
            return false
        }
    }

    /// Display name or email for UI
    var displayNameOrEmail: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        if let email = email {
            // Show only the part before @ for privacy
            return email.components(separatedBy: "@").first ?? email
        }
        return "User"
    }
}

// MARK: - SubscriptionStatus

/// Subscription status for a user.
enum SubscriptionStatus: String, Codable, Sendable {
    /// No subscription
    case none
    /// Free trial period
    case trial
    /// Active paid subscription
    case active
    /// Subscription has expired
    case expired
    /// User cancelled subscription
    case cancelled = "canceled"

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .none: return "No Subscription"
        case .trial: return "Free Trial"
        case .active: return "Active"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        }
    }

    /// Whether this status allows access to premium features
    var hasAccess: Bool {
        switch self {
        case .active, .trial:
            return true
        case .none, .expired, .cancelled:
            return false
        }
    }
}

// MARK: - AuthResponse

/// Response from the authentication server.
struct AuthResponse: Codable {
    let token: String
    let subscription: SubscriptionInfo

    struct SubscriptionInfo: Codable {
        let status: String
        let expiresAt: String?
    }
}

// MARK: - AuthError

/// Errors that can occur during authentication.
enum AuthError: LocalizedError {
    case signInCancelled
    case signInFailed(Error)
    case invalidCredential
    case serverValidationFailed(String)
    case noIdentityToken
    case sessionExpired
    case accountDeletionFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .signInCancelled:
            return "Sign in was cancelled"
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .invalidCredential:
            return "Invalid credential received"
        case .serverValidationFailed(let message):
            return "Server validation failed: \(message)"
        case .noIdentityToken:
            return "No identity token received from Apple"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .accountDeletionFailed(let message):
            return "Account deletion failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
