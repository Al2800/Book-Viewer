import SwiftUI

// MARK: - Quality Overlay View

/// Real-time quality feedback overlay shown during page capture.
/// Non-blocking: users can still capture even with warnings.
struct QualityOverlayView: View {
    let qualityResult: ImageQualityAnalyzer.QualityResult?
    var isExpanded: Bool = false
    var onExpandToggle: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Top overlay with quality summary
            topOverlay
                .transition(.move(edge: .top).combined(with: .opacity))

            Spacer()

            // Bottom capture status
            if let result = qualityResult {
                bottomOverlay(result: result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smoothSpring, value: qualityResult?.overallScore)
        .animation(.smoothSpring, value: isExpanded)
    }

    // MARK: - Top Overlay

    @ViewBuilder
    private var topOverlay: some View {
        if let result = qualityResult {
            VStack(spacing: Spacing.sm) {
                // Main quality indicator
                HStack(spacing: Spacing.md) {
                    QualityMeter(score: result.overallScore, label: "Quality")

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(qualityStatusText(for: result))
                            .font(.headline)
                            .foregroundStyle(qualityStatusColor(for: result))

                        if !result.issues.isEmpty {
                            Text("\(result.issues.count) issue\(result.issues.count == 1 ? "" : "s") detected")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    Spacer()

                    // Expand/collapse button
                    if onExpandToggle != nil {
                        Button {
                            HapticManager.impact(.light)
                            onExpandToggle?()
                        } label: {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                                .padding(Spacing.sm)
                        }
                    }
                }

                // Expanded metrics
                if isExpanded {
                    expandedMetrics(result: result)
                }

                // Compact issue badges (when collapsed)
                if !isExpanded && !result.issues.isEmpty {
                    IssueCompactRow(issues: result.issues)
                }
            }
            .padding(Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
    }

    // MARK: - Expanded Metrics

    @ViewBuilder
    private func expandedMetrics(result: ImageQualityAnalyzer.QualityResult) -> some View {
        VStack(spacing: Spacing.sm) {
            Divider()
                .padding(.vertical, Spacing.xs)

            // Individual metrics
            QualityMetricRow(
                icon: "camera.metering.center.weighted",
                label: "Sharpness",
                score: normalizedBlurScore(result.blurScore),
                details: blurDetails(score: result.blurScore)
            )

            QualityMetricRow(
                icon: brightnessIcon(for: result.brightnessScore),
                label: "Lighting",
                score: normalizedBrightnessScore(result.brightnessScore),
                details: brightnessDetails(score: result.brightnessScore)
            )

            QualityMetricRow(
                icon: "text.magnifyingglass",
                label: "Text Clarity",
                score: result.textConfidence,
                details: textDetails(confidence: result.textConfidence, count: result.textRegionCount)
            )

            // Issue advice (when expanded)
            if !result.issues.isEmpty {
                Divider()
                    .padding(.vertical, Spacing.xs)

                IssueAdviceList(issues: result.issues)
            }
        }
    }

    // MARK: - Bottom Overlay

    @ViewBuilder
    private func bottomOverlay(result: ImageQualityAnalyzer.QualityResult) -> some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Circle()
                .fill(result.isAcceptable ? Color.success : Color.warning)
                .frame(width: 12, height: 12)

            // Status text
            Text(result.isAcceptable ? "Ready to capture" : "Adjust for better results")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(result.isAcceptable ? Color.success : Color.warning)

            Spacer()

            // Can still capture warning
            if !result.isAcceptable {
                Text("Tap to capture anyway")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Helpers

    private func qualityStatusText(for result: ImageQualityAnalyzer.QualityResult) -> String {
        if result.isAcceptable {
            return result.overallScore >= 0.8 ? "Excellent" : "Good"
        } else if result.overallScore >= 0.4 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    private func qualityStatusColor(for result: ImageQualityAnalyzer.QualityResult) -> Color {
        if result.isAcceptable {
            return .success
        } else if result.overallScore >= 0.4 {
            return .warning
        } else {
            return .error
        }
    }

    // Normalize blur score to 0-1 (assuming 500 is excellent)
    private func normalizedBlurScore(_ score: Double) -> Double {
        min(1.0, score / 500.0)
    }

    // Normalize brightness score (0.5 is ideal)
    private func normalizedBrightnessScore(_ score: Double) -> Double {
        1.0 - abs(score - 0.5) * 2
    }

    private func blurDetails(score: Double) -> String {
        if score >= 150 {
            return "Sharp and clear"
        } else if score >= 100 {
            return "Acceptable sharpness"
        } else if score >= 50 {
            return "Slightly blurry"
        } else {
            return "Too blurry"
        }
    }

    private func brightnessIcon(for score: Double) -> String {
        if score < 0.3 {
            return "sun.min"
        } else if score > 0.7 {
            return "sun.max"
        } else {
            return "sun.max.fill"
        }
    }

    private func brightnessDetails(score: Double) -> String {
        if score < 0.2 {
            return "Too dark"
        } else if score < 0.3 {
            return "Slightly dark"
        } else if score > 0.8 {
            return "Too bright"
        } else if score > 0.7 {
            return "Slightly bright"
        } else {
            return "Good lighting"
        }
    }

    private func textDetails(confidence: Double, count: Int) -> String {
        if count == 0 {
            return "No text detected"
        } else if confidence >= 0.7 {
            return "\(count) region\(count == 1 ? "" : "s"), clear"
        } else if confidence >= 0.5 {
            return "\(count) region\(count == 1 ? "" : "s"), fair"
        } else {
            return "\(count) region\(count == 1 ? "" : "s"), unclear"
        }
    }
}

// MARK: - Minimal Quality Overlay

/// Simplified overlay showing just essential quality info
struct MinimalQualityOverlay: View {
    let qualityResult: ImageQualityAnalyzer.QualityResult?

    var body: some View {
        VStack {
            Spacer()

            if let result = qualityResult {
                HStack(spacing: Spacing.md) {
                    // Quality indicator
                    QualityIndicatorDot(score: result.overallScore)

                    // Status text
                    Text(result.isAcceptable ? "Ready" : "Adjust")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(result.isAcceptable ? Color.success : Color.warning)

                    // Issue count
                    if !result.issues.isEmpty {
                        Text("• \(result.issues.count) issue\(result.issues.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Quality Overlay - Good") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        QualityOverlayView(
            qualityResult: .init(
                overallScore: 0.85,
                blurScore: 250,
                brightnessScore: 0.55,
                textConfidence: 0.82,
                textRegionCount: 5,
                issues: [],
                isAcceptable: true
            ),
            isExpanded: true
        )
    }
}

#Preview("Quality Overlay - Issues") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        QualityOverlayView(
            qualityResult: .init(
                overallScore: 0.45,
                blurScore: 80,
                brightnessScore: 0.15,
                textConfidence: 0.35,
                textRegionCount: 2,
                issues: [
                    .tooBlurry(advice: "Hold the camera steady"),
                    .tooDark(advice: "Move to brighter area")
                ],
                isAcceptable: false
            ),
            isExpanded: true
        )
    }
}

#Preview("Minimal Overlay") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        MinimalQualityOverlay(
            qualityResult: .init(
                overallScore: 0.65,
                blurScore: 120,
                brightnessScore: 0.45,
                textConfidence: 0.6,
                textRegionCount: 3,
                issues: [.lowTextConfidence(advice: "Adjust angle")],
                isAcceptable: false
            )
        )
    }
}
