import SwiftUI

// MARK: - Quality Meter

/// Circular or linear meter showing quality score with color gradient
struct QualityMeter: View {
    let score: Double
    let label: String

    @State private var animatedScore: Double = 0

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.backgroundSecondary, lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedScore)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: Spacing.xxs) {
                    Text("\(Int(animatedScore * 100))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(scoreColor)

                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(width: 80, height: 80)
        }
        .onAppear {
            withAnimation(.smoothSpring) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.smoothSpring) {
                animatedScore = newValue
            }
        }
    }

    private var scoreColor: Color {
        switch animatedScore {
        case 0..<0.4:
            return .error
        case 0.4..<0.7:
            return .warning
        default:
            return .success
        }
    }
}

// MARK: - Linear Quality Meter

/// Linear meter variant for compact layouts
struct LinearQualityMeter: View {
    let score: Double
    let label: String
    var showPercentage: Bool = true

    @State private var animatedScore: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                Spacer()

                if showPercentage {
                    Text("\(Int(animatedScore * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(scoreColor)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.backgroundSecondary)

                    // Progress
                    Capsule()
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * animatedScore)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.smoothSpring) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.smoothSpring) {
                animatedScore = newValue
            }
        }
    }

    private var scoreColor: Color {
        switch animatedScore {
        case 0..<0.4:
            return .error
        case 0.4..<0.7:
            return .warning
        default:
            return .success
        }
    }
}

// MARK: - Mini Quality Indicator

/// Small indicator dot showing quality level
struct QualityIndicatorDot: View {
    let score: Double

    var body: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            }
    }

    private var indicatorColor: Color {
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

#Preview("Quality Meter") {
    VStack(spacing: Spacing.xl) {
        HStack(spacing: Spacing.xl) {
            QualityMeter(score: 0.25, label: "Poor")
            QualityMeter(score: 0.55, label: "Fair")
            QualityMeter(score: 0.85, label: "Good")
        }

        VStack(spacing: Spacing.md) {
            LinearQualityMeter(score: 0.25, label: "Sharpness")
            LinearQualityMeter(score: 0.55, label: "Lighting")
            LinearQualityMeter(score: 0.85, label: "Text Clarity")
        }
        .padding(.horizontal)

        HStack(spacing: Spacing.sm) {
            QualityIndicatorDot(score: 0.25)
            QualityIndicatorDot(score: 0.55)
            QualityIndicatorDot(score: 0.85)
        }
    }
    .padding()
}
