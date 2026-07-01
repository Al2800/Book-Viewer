import StoreKit
import SwiftUI

/// Simplified paywall for embedding in onboarding.
struct PaywallEmbeddedView: View {
    let subscriptionService: SubscriptionService
    let onContinue: () -> Void

    @State private var selectedProduct: Product?
    @State private var selectedMediaPlan: MediaSubscriptionPlan = .yearly
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundStyle(Color.brand)
                Text(selectedProduct?.freeTrialDescription ?? "Start with a 7-day free trial")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(Color.brand.opacity(0.1))
            .clipShape(Capsule())

            Group {
                if subscriptionService.isLoading {
                    ProgressView()
                        .padding(.vertical, Spacing.xl)
                } else if shouldShowMediaPlans {
                    mediaPlanOptions
                } else if subscriptionService.products.isEmpty {
                    emptyProductsMessage
                } else {
                    productOptions
                }
            }

            Spacer()

            trialButton

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            Button("Maybe later") {
                onContinue()
            }
            .foregroundStyle(Color.textSecondary)
            .padding(.bottom, Spacing.lg)
        }
        .task {
            if subscriptionService.products.isEmpty {
                await subscriptionService.loadProducts()
            }
            selectedProduct = subscriptionService.yearlyProduct ?? subscriptionService.monthlyProduct
        }
    }

    private var shouldShowMediaPlans: Bool {
        UITestConfiguration.shouldOpenSubscriptionMediaScreen && subscriptionService.products.isEmpty
    }

    private var mediaPlanOptions: some View {
        VStack(spacing: Spacing.md) {
            ForEach(MediaSubscriptionPlan.allCases) { plan in
                MediaSubscriptionOptionCard(
                    plan: plan,
                    isSelected: selectedMediaPlan == plan
                ) {
                    selectedMediaPlan = plan
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var emptyProductsMessage: some View {
        Text("Unable to load subscription options right now.")
            .font(.subheadline)
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.xl)
    }

    private var productOptions: some View {
        VStack(spacing: Spacing.md) {
            ForEach(subscriptionService.products) { product in
                SubscriptionOptionCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    monthlyProduct: subscriptionService.monthlyProduct
                ) {
                    selectedProduct = product
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var trialButton: some View {
        Button {
            startTrial()
        } label: {
            if isProcessing {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Start Free Trial")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.brand)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .padding(.horizontal, Spacing.lg)
        .disabled(isProcessing || (!shouldShowMediaPlans && selectedProduct == nil))
    }

    private func startTrial() {
        if shouldShowMediaPlans {
            onContinue()
            return
        }

        guard let selectedProduct else { return }
        isProcessing = true
        errorMessage = nil

        Task {
            defer { isProcessing = false }

            do {
                let transaction = try await subscriptionService.purchase(selectedProduct)
                if transaction != nil || subscriptionService.hasActiveSubscription {
                    onContinue()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
