import SwiftUI
import StoreKit

// MARK: - PaywallView

/// Full-screen paywall for subscription purchase.
struct PaywallView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let subscriptionService: SubscriptionService

    // MARK: - State

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    headerSection

                    // Features
                    PremiumFeatureList()

                    // Pricing options
                    pricingSection

                    // Subscribe button
                    subscribeButton

                    // Restore purchases
                    restoreButton

                    // Legal
                    legalSection
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Unlock BookQuotes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                if subscriptionService.products.isEmpty {
                    await subscriptionService.loadProducts()
                }
                // Default to yearly if available
                selectedProduct = subscriptionService.yearlyProduct ?? subscriptionService.monthlyProduct
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.brand)

            Text("Capture the wisdom\nin your books")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Start your 7-day free trial")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Spacing.md) {
            if subscriptionService.isLoading {
                ProgressView()
                    .padding()
            } else if subscriptionService.products.isEmpty {
                Text("Unable to load subscription options")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(subscriptionService.products) { product in
                    SubscriptionOptionCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        monthlyProduct: subscriptionService.monthlyProduct
                    ) {
                        withAnimation(.spring(duration: 0.2)) {
                            selectedProduct = product
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(buttonTitle)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedProduct == nil || isPurchasing)
    }

    private var buttonTitle: String {
        if let product = selectedProduct, product.hasFreeTrial {
            return "Start Free Trial"
        }
        return "Subscribe Now"
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await restore()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: Spacing.xs) {
            if let product = selectedProduct {
                Text(subscriptionTerms(for: product))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Spacing.md) {
                if let termsURL = URL(string: "https://bookquotes.app/terms") {
                    Link("Terms", destination: termsURL)
                } else {
                    Text("Terms")
                }
                Text("•")
                    .foregroundStyle(.secondary)
                if let privacyURL = URL(string: "https://bookquotes.app/privacy") {
                    Link("Privacy", destination: privacyURL)
                } else {
                    Text("Privacy")
                }
            }
            .font(.caption2)
        }
        .padding(.top, Spacing.md)
    }

    private func subscriptionTerms(for product: Product) -> String {
        var terms = ""

        if let trialDescription = product.freeTrialDescription {
            terms += "\(trialDescription), then "
        }

        terms += "\(product.priceWithPeriod). "
        terms += "Auto-renews until cancelled."

        return terms
    }

    // MARK: - Actions

    private func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let transaction = try await subscriptionService.purchase(product)
            if transaction != nil {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.hasActiveSubscription {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(subscriptionService: SubscriptionService(authService: AuthService()))
}
