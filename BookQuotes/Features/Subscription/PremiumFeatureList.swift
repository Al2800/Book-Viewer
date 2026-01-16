import SwiftUI

// MARK: - PremiumFeatureList

/// List of premium features shown on paywall.
struct PremiumFeatureList: View {

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            PremiumFeatureRow(
                icon: "wand.and.stars",
                title: "AI-Powered Extraction",
                description: "Automatically extract quotes from photos of book pages"
            )

            PremiumFeatureRow(
                icon: "infinity",
                title: "Unlimited Captures",
                description: "Capture as many quotes as you want, no limits"
            )

            PremiumFeatureRow(
                icon: "icloud",
                title: "Sync Everywhere",
                description: "Access your library on all your Apple devices"
            )

            PremiumFeatureRow(
                icon: "magnifyingglass",
                title: "Smart Search",
                description: "Find any quote instantly with full-text search"
            )

            PremiumFeatureRow(
                icon: "square.and.arrow.up",
                title: "Export Options",
                description: "Export quotes to Markdown, CSV, or JSON"
            )

            PremiumFeatureRow(
                icon: "person.badge.shield.checkmark",
                title: "Privacy First",
                description: "Your quotes stay private, never shared or used for training"
            )
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - PremiumFeatureRow

/// Single feature row in the premium features list.
struct PremiumFeatureRow: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let description: String

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Compact Feature List

/// Compact horizontal feature badges for inline display.
struct CompactFeatureList: View {

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FeatureBadge(icon: "wand.and.stars", text: "AI Extraction")
                FeatureBadge(icon: "infinity", text: "Unlimited")
                FeatureBadge(icon: "icloud", text: "Sync")
                FeatureBadge(icon: "magnifyingglass", text: "Search")
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Feature Badge

/// Small badge showing a feature.
private struct FeatureBadge: View {

    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview("Full List") {
    PremiumFeatureList()
        .padding()
}

#Preview("Compact") {
    CompactFeatureList()
}
