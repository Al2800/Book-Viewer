import AuthenticationServices
import Foundation
import UIKit

// MARK: - AuthService

/// Service handling Apple Sign-In authentication and session management.
@MainActor
@Observable
final class AuthService: NSObject {

    // MARK: - Properties

    /// Currently authenticated user
    private(set) var currentUser: User?

    /// Whether authentication is in progress
    private(set) var isAuthenticating = false

    /// Last authentication error
    private(set) var lastError: AuthError?

    /// Keychain service for secure storage
    private let keychainService: KeychainService

    /// Base URL for the authentication server
    private let serverBaseURL: URL

    /// Default server base URL
    nonisolated static let proxyBaseURL: URL = {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "BookQuotesProxyBaseURL") as? String,
           let url = resolveBaseURL(from: configured),
           configured.contains("your-worker") == false {
            return url
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.bookquotes.uk"
        return components.url ?? URL(fileURLWithPath: "/")
    }()

    // MARK: - Computed Properties

    /// Whether a user is currently authenticated
    var isAuthenticated: Bool {
        currentUser != nil && currentUser?.sessionToken != nil
    }

    /// Whether the user has an active subscription
    var hasActiveSubscription: Bool {
        currentUser?.hasActiveSubscription ?? false
    }

    // MARK: - Initialization

    init(
        keychainService: KeychainService = KeychainService(),
        serverBaseURL: URL = AuthService.proxyBaseURL
    ) {
        self.keychainService = keychainService
        self.serverBaseURL = serverBaseURL
        super.init()
    }

    // MARK: - Sign In

    /// Initiate Apple Sign-In flow
    func signInWithApple() async throws -> User {
        isAuthenticating = true
        lastError = nil

        defer { isAuthenticating = false }

        // Create Apple Sign-In request
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]

        // Perform sign-in
        let result = try await performSignIn(request: request)
        return try await completeSignIn(with: result)
    }

    /// Complete sign-in using an existing authorization result
    func signInWithApple(authorization: ASAuthorization) async throws -> User {
        isAuthenticating = true
        lastError = nil

        defer { isAuthenticating = false }

        return try await completeSignIn(with: authorization)
    }

    /// Perform the Apple Sign-In authorization
    private func performSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = SignInDelegate(continuation: continuation)

            // Store delegate to prevent deallocation
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
        }
    }

    private func completeSignIn(with authorization: ASAuthorization) async throws -> User {
        // Validate with our server and get session token
        let user = try await validateWithServer(authorization: authorization)

        // Store credentials in keychain
        try await storeCredentials(user: user)

        currentUser = user
        return user
    }

    /// Validate Apple credential with our backend server
    private func validateWithServer(authorization: ASAuthorization) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.noIdentityToken
        }

        // Build display name from name components
        var displayName: String?
        if let fullName = credential.fullName {
            let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !components.isEmpty {
                displayName = components.joined(separator: " ")
            }
        }

        // Send to our server for validation
        let url = serverBaseURL.appendingPathComponent("api/auth/apple")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(identityToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"
            throw AuthError.serverValidationFailed(
                trimServerError(
                    errorMessage,
                    url: serverBaseURL,
                    statusCode: httpResponse.statusCode,
                    contentType: contentType
                )
            )
        }

        // Parse response
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Parse subscription status
        let status = SubscriptionStatus(rawValue: authResponse.subscription.status) ?? .none
        var expiresAt: Date?
        if let expiresString = authResponse.subscription.expiresAt {
            let formatter = ISO8601DateFormatter()
            expiresAt = formatter.date(from: expiresString)
        }

        return User(
            id: credential.user,
            email: credential.email,
            displayName: displayName,
            subscriptionStatus: status,
            subscriptionExpiresAt: expiresAt,
            sessionToken: authResponse.token
        )
    }

    nonisolated private static func resolveBaseURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = trimmed
        return components.url
    }

    private func trimServerError(
        _ message: String,
        url: URL,
        statusCode: Int = -1,
        contentType: String = "unknown"
    ) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("<html") == false else {
            return "Server returned HTML (\(statusCode), \(contentType)). Check BookQuotesProxyBaseURL and /api/auth/apple. URL: \(url.absoluteString)"
        }

        if trimmed.count <= 280 {
            return "[\(statusCode), \(contentType)] \(trimmed)"
        }

        let index = trimmed.index(trimmed.startIndex, offsetBy: 280)
        return "[\(statusCode), \(contentType)] \(trimmed[..<index])…"
    }

    // MARK: - Session Management

    /// Restore session from keychain on app launch
    func restoreSession() async -> Bool {
        guard let userId = keychainService.getUserId(),
              let sessionToken = keychainService.getSessionToken() else {
            return false
        }

        // Verify the token is still valid with the server
        do {
            let user = try await refreshSession(userId: userId, sessionToken: sessionToken)
            currentUser = user
            return true
        } catch {
            // Clear invalid session
            await signOut()
            return false
        }
    }

    /// Refresh session with server to get updated subscription status
    private func refreshSession(userId: String, sessionToken: String) async throws -> User {
        let url = serverBaseURL.appendingPathComponent("api/usage")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }

        if httpResponse.statusCode == 401 {
            throw AuthError.sessionExpired
        }

        guard httpResponse.statusCode == 200 else {
            throw AuthError.serverValidationFailed("Failed to refresh session")
        }

        applyRefreshedSessionToken(from: httpResponse)
        let refreshedToken = keychainService.getSessionToken() ?? sessionToken

        // Parse usage response to get subscription status
        struct UsageResponse: Codable {
            let subscriptionStatus: String
            let expiresAt: String?
        }

        let usageResponse = try JSONDecoder().decode(UsageResponse.self, from: data)
        let status = SubscriptionStatus(rawValue: usageResponse.subscriptionStatus) ?? .none

        var expiresAt: Date?
        if let expiresString = usageResponse.expiresAt {
            let formatter = ISO8601DateFormatter()
            expiresAt = formatter.date(from: expiresString)
        }

        // Restore user with stored info
        let email = keychainService.getUserEmail()
        let displayName = keychainService.getUserDisplayName()

        return User(
            id: userId,
            email: email,
            displayName: displayName,
            subscriptionStatus: status,
            subscriptionExpiresAt: expiresAt,
            sessionToken: refreshedToken
        )
    }

    /// Sign out the current user
    func signOut() async {
        currentUser = nil
        keychainService.clearAllCredentials()
    }

    /// Delete the user's server-side account data, then clear the local session.
    /// Local library data remains on device. App Store subscriptions must be
    /// cancelled separately through Apple subscription management.
    func deleteAccount() async throws {
        guard let token = getSessionToken() else {
            throw AuthError.sessionExpired
        }

        let url = serverBaseURL.appendingPathComponent("api/auth/account")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(URLError(.badServerResponse))
        }

        applyRefreshedSessionToken(from: httpResponse)

        if httpResponse.statusCode == 401 {
            await signOut()
            throw AuthError.sessionExpired
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw AuthError.accountDeletionFailed(
                trimServerError(message, url: url, statusCode: httpResponse.statusCode)
            )
        }

        await signOut()
    }

    // MARK: - Credential Storage

    /// Store user credentials in keychain
    private func storeCredentials(user: User) async throws {
        keychainService.setUserId(user.id)

        if let token = user.sessionToken {
            keychainService.setSessionToken(token)
        }

        if let email = user.email {
            keychainService.setUserEmail(email)
        }

        if let displayName = user.displayName {
            keychainService.setUserDisplayName(displayName)
        }
    }

    /// Get the current session token for API requests
    func getSessionToken() -> String? {
        currentUser?.sessionToken ?? keychainService.getSessionToken()
    }

    /// Persist a sliding-session token returned by the proxy (`X-Session-Token`).
    func applyRefreshedSessionToken(from response: HTTPURLResponse) {
        guard let token = response.value(forHTTPHeaderField: "X-Session-Token")?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              token.isEmpty == false else {
            return
        }

        keychainService.setSessionToken(token)
        guard var user = currentUser else { return }
        user.sessionToken = token
        currentUser = user
    }

    /// Keep the in-memory user model aligned with StoreKit/backend subscription changes.
    func updateSubscriptionState(status: SubscriptionStatus, expiresAt: Date?) {
        guard var currentUser else { return }
        currentUser.subscriptionStatus = status
        currentUser.subscriptionExpiresAt = expiresAt
        self.currentUser = currentUser
    }
}

// MARK: - SignInDelegate

/// Delegate for handling Apple Sign-In callbacks
private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private let continuation: CheckedContinuation<ASAuthorization, Error>
    private var fallbackWindow: UIWindow?

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation.resume(throwing: AuthError.signInCancelled)
            default:
                continuation.resume(throwing: AuthError.signInFailed(error))
            }
        } else {
            continuation.resume(throwing: AuthError.signInFailed(error))
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Prefer a foreground-active window scene; returning an unattached UIWindow can cause
        // ASAuthorizationError.unknown (1000) in some real-world situations.
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let preferredScene = scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first(where: { $0.activationState == .foregroundInactive })
            ?? scenes.first

        if let window = preferredScene?.windows.first(where: { $0.isKeyWindow })
            ?? preferredScene?.windows.first {
            return window
        }

        if let anyWindow = scenes.flatMap(\.windows).first {
            return anyWindow
        }

        // Last resort: create a temporary attached window for presentation.
        if let scene = preferredScene {
            let window = UIWindow(windowScene: scene)
            window.rootViewController = UIViewController()
            window.isHidden = false
            window.makeKeyAndVisible()
            fallbackWindow = window
            return window
        }

        // If there is truly no scene, return a window (may still fail if not attached).
        let window = UIWindow(frame: UIScreen.main.bounds)
        fallbackWindow = window
        return window
    }
}

// MARK: - KeychainService Extensions

extension KeychainService {

    private static let userIdKey = "com.bookquotes.userId"
    private static let sessionTokenKey = "com.bookquotes.sessionToken"
    private static let userEmailKey = "com.bookquotes.userEmail"
    private static let userDisplayNameKey = "com.bookquotes.userDisplayName"

    func getUserId() -> String? {
        getString(forKey: Self.userIdKey)
    }

    func setUserId(_ userId: String) {
        setString(userId, forKey: Self.userIdKey)
    }

    func getSessionToken() -> String? {
        getString(forKey: Self.sessionTokenKey)
    }

    func setSessionToken(_ token: String) {
        setString(token, forKey: Self.sessionTokenKey)
    }

    func getUserEmail() -> String? {
        getString(forKey: Self.userEmailKey)
    }

    func setUserEmail(_ email: String) {
        setString(email, forKey: Self.userEmailKey)
    }

    func getUserDisplayName() -> String? {
        getString(forKey: Self.userDisplayNameKey)
    }

    func setUserDisplayName(_ name: String) {
        setString(name, forKey: Self.userDisplayNameKey)
    }

    func clearAllCredentials() {
        delete(forKey: Self.userIdKey)
        delete(forKey: Self.sessionTokenKey)
        delete(forKey: Self.userEmailKey)
        delete(forKey: Self.userDisplayNameKey)
    }
}
