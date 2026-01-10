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
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "books.vertical.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.brand)

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
                icon: "icloud",
                title: "Sync Everywhere",
                description: "Access your library on all your devices"
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
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("By signing in, you agree to our")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.xs) {
                Link("Terms of Service", destination: URL(string: "https://bookquotes.app/terms")!)
                Text("and")
                    .foregroundStyle(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://bookquotes.app/privacy")!)
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
                let user = try await authService.signInWithApple()
                onSignInComplete?(user)
                dismiss()
            } catch AuthError.signInCancelled {
                // User cancelled - no error message needed
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
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
                .foregroundStyle(.brand)
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
                let user = try await authService.signInWithApple()
                onSignInComplete?(user)
            } catch AuthError.signInCancelled {
                // User cancelled
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignInView(authService: AuthService())
}
