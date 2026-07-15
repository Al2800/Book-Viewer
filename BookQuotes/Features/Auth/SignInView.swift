import SwiftUI
import AuthenticationServices

// MARK: - SignInView

/// View for Apple Sign-In authentication.
struct SignInView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let authService: AuthService
    var onSignInComplete: ((User) -> Void)?

    // MARK: - State

    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var lastAuthorizationError: ASAuthorizationError?
    @State private var presentedLegalDocument: LegalDocument?

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // App branding
            brandingSection

            // Value proposition
            featuresSection

            Spacer()

            // Sign-in button
            signInButton

            // Terms and privacy
            legalSection
        }
        .padding(Spacing.lg)
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .sheet(item: $presentedLegalDocument) { document in
            LegalDocumentView(document: document)
        }
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "books.vertical.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brand)

            Text("BookQuotes")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Capture the wisdom in your books")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            FeatureRow(
                icon: "camera.viewfinder",
                title: "Smart Capture",
                description: "AI extracts quotes from your book photos"
            )

            FeatureRow(
                icon: AppReleaseConfiguration.cloudSyncEnabled ? "icloud" : "books.vertical",
                title: AppReleaseConfiguration.cloudSyncEnabled ? "Sync Everywhere" : "On-Device Library",
                description: AppReleaseConfiguration.cloudSyncEnabled
                    ? "Access your library on all your devices"
                    : "Your books and quotes stay stored on this iPhone or iPad"
            )

            FeatureRow(
                icon: "lock.shield",
                title: "Private & Secure",
                description: "Your data stays private with Apple Sign-In"
            )
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Sign-In Button

    private var signInButton: some View {
        VStack(spacing: Spacing.md) {
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.email, .fullName]
                },
                onCompletion: { result in
                    handleSignInResult(result)
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .cornerRadius(CornerRadius.md)
            .disabled(isSigningIn)

            if isSigningIn {
                ProgressView()
                    .progressViewStyle(.circular)
            }

            // If the system button path fails with error 1000, offer an alternate flow that uses our
            // explicit ASAuthorizationController presentation anchor handling.
            if let lastAuthorizationError, lastAuthorizationError.code == .unknown {
                Button("Try Alternate Sign In") {
                    Task {
                        await attemptAlternateSignIn()
                    }
                }
                .buttonStyle(.secondary)
                .disabled(isSigningIn)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("By signing in, you agree to our")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.xs) {
                LegalLinksRow(presentedDocument: $presentedLegalDocument)
            }
            .font(.caption)
        }
    }

    // MARK: - Actions

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            isSigningIn = true
            defer { isSigningIn = false }

            do {
                switch result {
                case .success(let authorization):
                    lastAuthorizationError = nil
                    let user = try await authService.signInWithApple(authorization: authorization)
                    onSignInComplete?(user)
                    dismiss()
                case .failure(let error):
                    throw error
                }
            } catch AuthError.signInCancelled {
                // User cancelled - no error message needed
            } catch {
                lastAuthorizationError = error as? ASAuthorizationError
                errorMessage = SignInErrorMessage.message(for: error)
                showError = true
            }
        }
    }

    private func attemptAlternateSignIn() async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            lastAuthorizationError = nil
            let user = try await authService.signInWithApple()
            onSignInComplete?(user)
            dismiss()
        } catch AuthError.signInCancelled {
            // no-op
        } catch {
            lastAuthorizationError = error as? ASAuthorizationError
            errorMessage = SignInErrorMessage.message(for: error)
            showError = true
        }
    }
}

// MARK: - FeatureRow

/// Row displaying a feature with icon and description.
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.brand)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - SignInButton (Standalone)

/// Standalone Sign in with Apple button for use in other views.
struct AppleSignInButton: View {
    let authService: AuthService
    var onSignInComplete: ((User) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage: String?

    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.email, .fullName]
            },
            onCompletion: { result in
                handleResult(result)
            }
        )
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .cornerRadius(CornerRadius.md)
        .disabled(isSigningIn)
        .overlay {
            if isSigningIn {
                ProgressView()
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            isSigningIn = true
            defer { isSigningIn = false }

            do {
                switch result {
                case .success(let authorization):
                    let user = try await authService.signInWithApple(authorization: authorization)
                    onSignInComplete?(user)
                case .failure(let error):
                    throw error
                }
            } catch AuthError.signInCancelled {
                // User cancelled
            } catch {
                errorMessage = SignInErrorMessage.message(for: error)
                showError = true
            }
        }
    }
}

private enum SignInErrorMessage {
    static func message(for error: Error) -> String {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .unknown:
                return "Sign in with Apple is unavailable for this build (error 1000). Ensure the app has the \"Sign In with Apple\" capability enabled and is signed with the correct entitlements, then install a new build."
            case .invalidResponse:
                return "Sign in with Apple returned an invalid response. Please try again."
            case .notHandled:
                return "Sign in with Apple could not be handled. Please try again."
            case .failed:
                return "Sign in with Apple failed. Please try again."
            case .canceled:
                return "Sign in was cancelled."
            default:
                return "Sign in with Apple could not be completed. Return to BookQuotes and try again."
            }
        }

        if let authError = error as? AuthError {
            return authError.localizedDescription
        }

        return error.localizedDescription
    }
}

// MARK: - Preview

#Preview {
    SignInView(authService: AuthService())
}
