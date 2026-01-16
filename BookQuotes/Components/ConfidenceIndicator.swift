import SwiftUI

// MARK: - ConfidenceIndicator

/// Visual indicator for AI extraction confidence scores.
/// Provides visual feedback on quote extraction reliability.
struct ConfidenceIndicator: View {

    // MARK: - Properties

    /// Confidence score (0.0 to 1.0)
    let confidence: Double

    /// Display style
    var style: IndicatorStyle = .dot

    // MARK: - Style

    enum IndicatorStyle {
        case dot       // Small colored dot
        case bar       // Horizontal progress bar
        case badge     // Text label badge
        case label     // Icon with text label
        case compact   // Small dot with percentage
    }

    // MARK: - Computed Properties

    /// Color based on confidence threshold
    var color: Color {
        switch confidence {
        case 0.9...: return .success
        case 0.7..<0.9: return .yellow
        case 0.5..<0.7: return .warning
        default: return .error
        }
    }

    /// Human-readable confidence level
    var label: String {
        switch confidence {
        case 0.9...: return "High"
        case 0.7..<0.9: return "Good"
        case 0.5..<0.7: return "Fair"
        default: return "Low"
        }
    }

    /// Percentage string
    var percentage: String {
        String(format: "%.0f%%", confidence * 100)
    }

    /// System icon for confidence level
    var iconName: String {
        switch confidence {
        case 0.9...: return "checkmark.circle.fill"
        case 0.7..<0.9: return "checkmark.circle"
        case 0.5..<0.7: return "exclamationmark.circle"
        default: return "questionmark.circle"
        }
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .dot:
            dotStyle

        case .bar:
            barStyle

        case .badge:
            badgeStyle

        case .label:
            labelStyle

        case .compact:
            compactStyle
        }
    }

    // MARK: - Dot Style

    private var dotStyle: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .accessibilityLabel("Confidence: \(label)")
    }

    // MARK: - Bar Style

    private var barStyle: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.2))

                // Fill
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * confidence))
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Confidence: \(percentage)")
    }

    // MARK: - Badge Style

    private var badgeStyle: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Confidence: \(label)")
    }

    // MARK: - Label Style

    private var labelStyle: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: iconName)
                .foregroundStyle(color)

            Text(percentage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Confidence: \(percentage), \(label)")
    }

    // MARK: - Compact Style

    private var compactStyle: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(percentage)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Confidence: \(percentage)")
    }
}

// MARK: - Convenience Initializer

extension ConfidenceIndicator {
    /// Initialize with an optional confidence value, defaulting to 1.0 if nil
    init(confidence: Double?, style: IndicatorStyle = .dot) {
        self.confidence = confidence ?? 1.0
        self.style = style
    }
}

// MARK: - View Extension

extension View {
    /// Add a confidence indicator overlay
    func confidenceOverlay(
        _ confidence: Double?,
        style: ConfidenceIndicator.IndicatorStyle = .dot,
        alignment: Alignment = .topTrailing
    ) -> some View {
        overlay(alignment: alignment) {
            if let conf = confidence {
                ConfidenceIndicator(confidence: conf, style: style)
                    .padding(4)
            }
        }
    }
}

// MARK: - Preview

#Preview("All Styles") {
    VStack(spacing: 32) {
        // Dot Style
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Dot Style").font(.headline)
            HStack(spacing: Spacing.lg) {
                ForEach([0.95, 0.80, 0.60, 0.30], id: \.self) { conf in
                    VStack {
                        ConfidenceIndicator(confidence: conf, style: ConfidenceIndicator.IndicatorStyle.dot)
                        Text("\(Int(conf * 100))%")
                            .font(.caption2)
                    }
                }
            }
        }

        Divider()

        // Bar Style
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Bar Style").font(.headline)
            ForEach([0.95, 0.80, 0.60, 0.30], id: \.self) { conf in
                HStack {
                    Text("\(Int(conf * 100))%")
                        .font(.caption)
                        .frame(width: 40)
                    ConfidenceIndicator(confidence: conf, style: .bar)
                        .frame(width: 100)
                }
            }
        }

        Divider()

        // Badge Style
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Badge Style").font(.headline)
            HStack(spacing: Spacing.md) {
                ForEach([0.95, 0.80, 0.60, 0.30], id: \.self) { conf in
                    ConfidenceIndicator(confidence: conf, style: .badge)
                }
            }
        }

        Divider()

        // Label Style
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Label Style").font(.headline)
            HStack(spacing: Spacing.lg) {
                ForEach([0.95, 0.80, 0.60, 0.30], id: \.self) { conf in
                    ConfidenceIndicator(confidence: conf, style: .label)
                }
            }
        }

        Divider()

        // Compact Style
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Compact Style").font(.headline)
            HStack(spacing: Spacing.lg) {
                ForEach([0.95, 0.80, 0.60, 0.30], id: \.self) { conf in
                    ConfidenceIndicator(confidence: conf, style: .compact)
                }
            }
        }
    }
    .padding()
}

#Preview("In Context") {
    VStack(spacing: 24) {
        // Quote card with confidence
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Every action you take is a vote...")
                    .font(.quoteBody)
                Spacer()
                ConfidenceIndicator(confidence: 0.92, style: ConfidenceIndicator.IndicatorStyle.dot)
            }
            Text("Atomic Habits - James Clear")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

        // Detail view with bar
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("AI Confidence")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                ConfidenceIndicator(confidence: 0.75, style: .bar)
                    .frame(width: 120)
                ConfidenceIndicator(confidence: 0.75, style: .badge)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

        // Low confidence warning
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.warning)
            Text("This quote may need review")
                .font(.caption)
            Spacer()
            ConfidenceIndicator(confidence: 0.45, style: .badge)
        }
        .padding()
        .background(Color.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    .padding()
}
