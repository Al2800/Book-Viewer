import SwiftUI
import StoreKit

// MARK: - SubscriptionOptionCard

/// Card displaying a subscription option for selection.
struct SubscriptionOptionCard: View {

    // MARK: - Properties

    let product: Product
    let isSelected: Bool
    let monthlyProduct: Product?
    let onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                // Selection indicator
                selectionIndicator

                // Product info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(productTitle)
                            .font(.headline)

                        if let savings = savingsPercentage {
                            Text("Save \(savings)%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.brand, in: Capsule())
                        }
                    }

                    if let trialDescription = product.freeTrialDescription {
                        Text(trialDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    Text(product.displayPrice)
                        .font(.headline)

                    if let monthlyEquivalent = product.monthlyEquivalent {
                        Text("\(monthlyEquivalent)/mo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(periodLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? Color.brand.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(
                        isSelected ? Color.brand : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .strokeBorder(isSelected ? Color.brand : Color.secondary.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)

            if isSelected {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 14, height: 14)
            }
        }
    }

    // MARK: - Computed Properties

    private var productTitle: String {
        if product.id.contains("yearly") {
            return "Yearly"
        } else if product.id.contains("monthly") {
            return "Monthly"
        }
        return product.displayName
    }

    private var periodLabel: String {
        guard let subscription = product.subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .month:
            return "per month"
        case .year:
            return "per year"
        case .week:
            return "per week"
        case .day:
            return "per day"
        @unknown default:
            return ""
        }
    }

    private var savingsPercentage: Int? {
        guard let monthly = monthlyProduct else { return nil }
        return product.savingsPercentage(comparedTo: monthly)
    }
}

// MARK: - Preview

#Preview {
    Group {
        if let yearly = Product.mockYearly, let monthly = Product.mockMonthly {
            VStack(spacing: Spacing.md) {
                SubscriptionOptionCard(
                    product: yearly,
                    isSelected: true,
                    monthlyProduct: monthly
                ) {}

                SubscriptionOptionCard(
                    product: monthly,
                    isSelected: false,
                    monthlyProduct: nil
                ) {}
            }
            .padding()
        } else {
            Text("StoreKit preview requires StoreKit Testing configuration.")
                .foregroundStyle(.secondary)
                .padding()
        }
    }
}

// MARK: - Mock Products for Preview

private extension Product {
    static var mockMonthly: Product? {
        nil
    }

    static var mockYearly: Product? {
        nil
    }
}
