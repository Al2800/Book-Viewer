import Foundation
import AuthenticationServices

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
        serverBaseURL: URL = URL(string: "https://bookquotes-proxy.your-worker.workers.dev")!
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

        // Validate with our server and get session token
        let user = try await validateWithServer(authorization: result)

        // Store credentials in keychain
        try await storeCredentials(user: user)

        currentUser = user
        return user
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
        let url = serverBaseURL.appendingPathComponent("/api/auth/apple")
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
            throw AuthError.serverValidationFailed(errorMessage)
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
        let url = serverBaseURL.appendingPathComponent("/api/usage")
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
            sessionToken: sessionToken
        )
    }

    /// Sign out the current user
    func signOut() async {
        currentUser = nil
        keychainService.clearAllCredentials()
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
}

// MARK: - SignInDelegate

/// Delegate for handling Apple Sign-In callbacks
private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private let continuation: CheckedContinuation<ASAuthorization, Error>

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
        // Return the key window for presenting the sign-in sheet
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window available for Sign in with Apple")
        }
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
