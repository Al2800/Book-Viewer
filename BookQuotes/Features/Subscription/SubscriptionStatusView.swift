import SwiftUI
import StoreKit

// MARK: - SubscriptionStatusView

/// View showing current subscription status and management options.
struct SubscriptionStatusView: View {

    // MARK: - Properties

    let subscriptionService: SubscriptionService

    // MARK: - State

    @State private var showManageSheet = false

    // MARK: - Body

    var body: some View {
        List {
            // Current subscription section
            Section {
                currentSubscriptionRow
            } header: {
                Text("Current Plan")
            }

            // Subscription details
            if let product = subscriptionService.purchasedSubscription {
                Section {
                    detailRow(title: "Price", value: product.priceWithPeriod)

                    if subscriptionService.subscriptionStatus != nil {
                        detailRow(title: "Renewal", value: "Renews automatically")
                    }

                    if subscriptionService.isInTrial {
                        detailRow(title: "Status", value: "Free Trial")
                            .foregroundStyle(Color.brand)
                    }
                } header: {
                    Text("Details")
                }
            }

            // Management section
            Section {
                Button {
                    Task {
                        await subscriptionService.manageSubscription()
                    }
                } label: {
                    Label("Manage Subscription", systemImage: "creditcard")
                }

                Button {
                    Task {
                        try? await subscriptionService.restorePurchases()
                    }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Manage")
            } footer: {
                Text("Manage your subscription, update payment method, or cancel in your Apple ID settings.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.backgroundPrimary)
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscriptionService.updateSubscriptionStatus()
        }
    }

    // MARK: - Current Subscription Row

    private var currentSubscriptionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if subscriptionService.hasActiveSubscription {
                    Text(subscriptionTitle)
                        .font(.headline)

                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(Color.success)
                } else {
                    Text("No Active Subscription")
                        .font(.headline)

                    Text("Subscribe to unlock all features")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if subscriptionService.hasActiveSubscription {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.success)
                    .font(.title2)
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

    // MARK: - Helper Views

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

// MARK: - SubscriptionBadge

/// Compact badge showing subscription status.
struct SubscriptionBadge: View {

    let subscriptionService: SubscriptionService

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if subscriptionService.hasActiveSubscription {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Color.accent)
                Text(subscriptionService.isInTrial ? "Trial" : "Premium")
            } else {
                Image(systemName: "sparkles")
                Text("Free")
            }
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(subscriptionService.hasActiveSubscription ? Color.accent.opacity(0.2) : Color.secondary.opacity(0.1))
        )
    }
}

// MARK: - UpgradePrompt

/// Inline prompt to upgrade to premium.
struct UpgradePrompt: View {

    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(Color.brand)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Unlock Premium")
                        .font(.headline)

                    Text("Start a 7-day free trial, then continue with monthly or yearly auto-renewing access.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Upgrade", action: onUpgrade)
                    .buttonStyle(.primaryCompact)
                    .controlSize(.small)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionStatusView(
            subscriptionService: SubscriptionService(authService: AuthService())
        )
    }
}
