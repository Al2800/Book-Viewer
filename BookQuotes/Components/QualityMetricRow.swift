import SwiftUI

// MARK: - Quality Metric Row

/// Row showing a single quality metric with icon, label, and score
struct QualityMetricRow: View {
    let icon: String
    let label: String
    let score: Double
    var details: String?
    var isOK: Bool { score >= 0.6 }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(isOK ? Color.success : scoreColor)
                .frame(width: 24)

            // Label and details
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)

                if let details {
                    Text(details)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            // Score indicator
            HStack(spacing: Spacing.xs) {
                if isOK {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.success)
                } else {
                    LinearQualityMeter(score: score, label: "", showPercentage: false)
                        .frame(width: 60)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var scoreColor: Color {
        switch score {
        case 0..<0.4:
            return .error
        case 0.4..<0.7:
            return .warning
        default:
            return .success
        }
    }
}

// MARK: - Quality Metric Card

/// Card variant of quality metric for detailed view
struct QualityMetricCard: View {
    let icon: String
    let label: String
    let score: Double
    let description: String

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(scoreColor)

                Spacer()

                Text("\(Int(score * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
            }

            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(description)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LinearQualityMeter(score: score, label: "", showPercentage: false)
        }
        .padding(Spacing.md)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var scoreColor: Color {
        switch score {
        case 0..<0.4:
            return .error
        case 0.4..<0.7:
            return .warning
        default:
            return .success
        }
    }
}

// MARK: - Preview

#Preview("Quality Metric Row") {
    VStack(spacing: 0) {
        QualityMetricRow(
            icon: "camera.metering.center.weighted",
            label: "Sharpness",
            score: 0.85,
            details: "Image is sharp and clear"
        )
        Divider()
        QualityMetricRow(
            icon: "sun.max",
            label: "Lighting",
            score: 0.45,
            details: "Slightly too bright"
        )
        Divider()
        QualityMetricRow(
            icon: "text.magnifyingglass",
            label: "Text Clarity",
            score: 0.25,
            details: "No text detected"
        )
    }
    .padding()
}

#Preview("Quality Metric Card") {
    HStack(spacing: Spacing.md) {
        QualityMetricCard(
            icon: "camera.metering.center.weighted",
            label: "Sharpness",
            score: 0.85,
            description: "Image is focused and clear"
        )
        QualityMetricCard(
            icon: "sun.max",
            label: "Lighting",
            score: 0.45,
            description: "Adjust lighting for better results"
        )
    }
    .padding()
}
