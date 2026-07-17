import SwiftUI

/// Account and subscription management
struct AccountView: View {
    let authService: AuthService
    let subscriptionService: SubscriptionService

    @State private var showSignIn = false
    @State private var showPaywall = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var isRestoring = false
    @State private var showRestoreSuccess = false
    @State private var isDeletingAccount = false
    @State private var showError = false
    @State private var errorMessage: String?

    private var subscriptionsEnabled: Bool {
        AppReleaseConfiguration.subscriptionsEnabled
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if authService.isAuthenticated {
                    accountSection
                } else {
                    signInPromptSection
                }

                if subscriptionsEnabled {
                    subscriptionSection
                }

                actionsSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $showSignIn) {
            SignInView(authService: authService)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptionService: subscriptionService)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your data will remain on this device.")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your BookQuotes account data from our servers. Your local library stays on this device. Cancel any App Store subscription separately in Subscription settings if needed.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
            Button("OK") {}
        } message: {
            Text("Your BookQuotes subscription is active.")
        }
        .task {
            guard subscriptionsEnabled else { return }
            await subscriptionService.loadProducts()
        }
    }

    private var accountSection: some View {
        SectionCard(title: "Account") {
            HStack(spacing: Spacing.md) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.brand)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    if let user = authService.currentUser {
                        Text(user.displayNameOrEmail)
                            .font(.headline)

                        if let email = user.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if subscriptionsEnabled {
                    SubscriptionBadge(subscriptionService: subscriptionService)
                } else {
                    Text("Signed In")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var signInPromptSection: some View {
        SectionCard(title: "Account") {
            VStack(spacing: Spacing.md) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text("Optional Account")
                    .font(.headline)

                Text(
                    subscriptionsEnabled
                        ? "Your library, search, exports, and on-device quote extraction work without an account. Sign in with Apple only to use remote AI processing or manage a subscription."
                        : "Your library, search, exports, and on-device quote extraction work without an account. Sign in with Apple only to use remote AI processing."
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showSignIn = true
                } label: {
                    Label("Sign in with Apple", systemImage: "apple.logo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black)
                .accessibilityIdentifier(AccessibilityIdentifiers.Settings.signInButton)
            }
            .padding(.vertical, Spacing.md)
        }
    }

    private var subscriptionSection: some View {
        SectionCard(title: "Subscription") {
            if !authService.isAuthenticated {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sign In to View Plans")
                        .font(.headline)

                    Text("Sign in with Apple before purchasing or restoring so your subscription can be linked to your BookQuotes account.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button("Sign in with Apple") {
                        showSignIn = true
                    }
                    .buttonStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.xs)
            } else if subscriptionService.hasActiveSubscription {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text(subscriptionTitle)
                            .font(.headline)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.success)
                            .accessibilityHidden(true)
                    }

                    if subscriptionService.isInTrial {
                        Label("Free Trial Active", systemImage: "gift.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.brand)
                    }

                    Text("Renews automatically")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.xs)

                Divider()

                Button {
                    Task {
                        await subscriptionService.manageSubscription()
                    }
                } label: {
                    HStack {
                        Label("Manage Subscription", systemImage: "creditcard")
                            .foregroundStyle(Color.brand)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Unlock Premium")
                        .font(.headline)

                    Text("Start a 7-day free trial, then continue with monthly or yearly auto-renewing access.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        showPaywall = true
                    } label: {
                        Text("View Plans")
                    }
                    .buttonStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.xs)
            }
        }
    }

    private var subscriptionTitle: String {
        if let product = subscriptionService.purchasedSubscription {
            return planTitle(for: product.id, fallback: product.displayName)
        }

        if let productID = subscriptionService.purchasedProductID {
            return planTitle(for: productID, fallback: "BookQuotes Premium")
        }

        return "BookQuotes Premium"
    }

    private func planTitle(for productID: String, fallback: String) -> String {
        if productID.contains("yearly") {
            return "BookQuotes Yearly"
        } else if productID.contains("monthly") {
            return "BookQuotes Monthly"
        }

        return fallback
    }

    @ViewBuilder
    private var actionsSection: some View {
        if authService.isAuthenticated {
            SectionCard(title: "Manage") {
                if subscriptionsEnabled {
                    Button {
                        Task {
                            await restorePurchases()
                        }
                    } label: {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(Color.brand)

                            Spacer()

                            if isRestoring {
                                ProgressView()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isRestoring)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.restorePurchasesButton)
                }

                if subscriptionsEnabled && authService.isAuthenticated {
                    Divider()
                }

                if authService.isAuthenticated {
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(Color.error)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.signOutButton)

                    Divider()

                    Button {
                        showDeleteAccountConfirmation = true
                    } label: {
                        HStack {
                            Label("Delete Account", systemImage: "trash")
                                .foregroundStyle(Color.error)

                            Spacer()

                            if isDeletingAccount {
                                ProgressView()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeletingAccount)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Settings.deleteAccountButton)
                }
            }
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await subscriptionService.restorePurchases()
            showRestoreSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func signOut() {
        Task {
            await authService.signOut()
        }
    }

    private func deleteAccount() {
        Task {
            isDeletingAccount = true
            defer { isDeletingAccount = false }

            do {
                try await authService.deleteAccount()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview("Account - Signed Out") {
    NavigationStack {
        AccountView(
            authService: AuthService(),
            subscriptionService: SubscriptionService(authService: AuthService())
        )
    }
}
