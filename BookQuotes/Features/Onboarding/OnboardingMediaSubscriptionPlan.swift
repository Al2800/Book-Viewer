import SwiftUI

enum MediaSubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .yearly: return "$39.99"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Flexible access for regular readers"
        case .yearly: return "Best value for committed readers"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "per year"
        }
    }

    var badge: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Best Value"
        }
    }
}

struct MediaSubscriptionOptionCard: View {
    let plan: MediaSubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                selectionIndicator
                planCopy
                Spacer()
                planPrice
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isSelected ? Color.brand.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .strokeBorder(isSelected ? Color.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

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

    private var planCopy: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(plan.title)
                    .font(.headline)

                if let badge = plan.badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.brand, in: Capsule())
                }
            }

            Text("7-day free trial for eligible new subscribers")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(plan.subtitle)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var planPrice: some View {
        VStack(alignment: .trailing, spacing: Spacing.xxs) {
            Text(plan.price)
                .font(.headline)

            Text(plan.period)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
