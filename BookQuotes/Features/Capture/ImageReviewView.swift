import SwiftUI

// MARK: - Image Review View

/// Sheet view for reviewing a captured image before processing.
/// Allows user to retake or confirm the photo.
struct ImageReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let image: UIImage
    let qualityResult: ImageQualityAnalyzer.QualityResult?
    let isQualityFeedbackUnavailable: Bool
    let book: Book
    let onRetake: () -> Void
    let onConfirm: () -> Void

    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image preview
                imagePreview
                    .frame(maxHeight: .infinity)
                    .background(Color.black)

                // Quality feedback
                if let result = qualityResult {
                    qualitySection(result)
                } else if isQualityFeedbackUnavailable {
                    qualityUnavailableSection
                }

                // Action buttons
                actionButtons
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Review Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .accessibilityIdentifier(AccessibilityIdentifiers.ImageReview.cancelButton)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(imageScale)
                .offset(imageOffset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                imageScale = max(1.0, min(value, 4.0))
                            }
                            .onEnded { _ in
                                if imageScale < 1.0 {
                                    withAnimation(.spring()) {
                                        imageScale = 1.0
                                        imageOffset = .zero
                                    }
                                }
                            },
                        DragGesture()
                            .onChanged { value in
                                if imageScale > 1.0 {
                                    imageOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = imageOffset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    toggleImageZoom()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .accessibilityLabel("Captured page preview")
                .accessibilityHint("Activate to zoom in or reset zoom")
                .accessibilityAction {
                    toggleImageZoom()
                }
        }
    }

    // MARK: - Quality Section

    private func qualitySection(_ result: ImageQualityAnalyzer.QualityResult) -> some View {
        VStack(spacing: Spacing.sm) {
            // Quality bar
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.md) {
                    overallQualityIndicator(result)
                    Spacer()
                    qualityMetrics(result)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    overallQualityIndicator(result)
                    qualityMetrics(result)
                }
            }
            .padding(Spacing.md)
            .background(Color.backgroundSecondary, in: RoundedRectangle(cornerRadius: CornerRadius.md))

            // Warnings if any
            if !result.issues.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Array(result.issues.prefix(2)), id: \.description) { issue in
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.warning)
                                .accessibilityHidden(true)

                            Text(issue.description)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .accessibilityIdentifier(AccessibilityIdentifiers.ImageReview.qualityBar)
    }

    private var qualityUnavailableSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Quality check unavailable", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.warning)

            Text("You can still review the image before continuing.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.backgroundSecondary, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .accessibilityIdentifier(AccessibilityIdentifiers.ImageReview.qualityBar)
    }

    private func metricIndicator(label: String, score: Double) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Circle()
                .fill(qualityColor(for: score))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(metricQualityLabel(for: score))")
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: Spacing.sm) {
                    retakeButton
                    usePhotoButton
                }
            } else {
                HStack(spacing: Spacing.lg) {
                    retakeButton
                    usePhotoButton
                }
            }
        }
        .padding(Spacing.lg)
        .glassFloating(cornerRadius: CornerRadius.xl)
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }

    private var retakeButton: some View {
        Button {
            onRetake()
            dismiss()
        } label: {
            Label("Retake", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.secondary)
        .accessibilityIdentifier(AccessibilityIdentifiers.ImageReview.retakeButton)
    }

    private var usePhotoButton: some View {
        Button {
            onConfirm()
            dismiss()
        } label: {
            Label("Use Photo", systemImage: "checkmark")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .glassButton()
        .accessibilityIdentifier(AccessibilityIdentifiers.ImageReview.usePhotoButton)
    }

    private func overallQualityIndicator(_ result: ImageQualityAnalyzer.QualityResult) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(qualityColor(for: result.overallScore))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            Text(qualityLabel(for: result.overallScore))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func qualityMetrics(_ result: ImageQualityAnalyzer.QualityResult) -> some View {
        HStack(spacing: Spacing.md) {
            metricIndicator(label: "Blur", score: normalizedBlurScore(result.blurScore))
            metricIndicator(label: "Light", score: normalizedBrightnessScore(result.brightnessScore))
            metricIndicator(label: "Text", score: result.textConfidence)
        }
    }

    // MARK: - Helpers

    private func toggleImageZoom() {
        withAnimation(.spring()) {
            if imageScale > 1.0 {
                imageScale = 1.0
                imageOffset = .zero
                lastOffset = .zero
            } else {
                imageScale = 2.5
            }
        }
    }

    private var shouldShowWarning: Bool {
        guard let result = qualityResult else { return false }
        return !result.isAcceptable && result.overallScore < 0.4
    }

    private func qualityColor(for score: Double) -> Color {
        if let result = qualityResult, result.isAcceptable {
            return .success
        }
        if score >= 0.75 {
            return .success
        } else if score >= 0.4 {
            return .warning
        } else {
            return .error
        }
    }

    private func qualityLabel(for score: Double) -> String {
        if let result = qualityResult, result.isAcceptable {
            return "Good Quality"
        }
        if score >= 0.75 {
            return "Good Quality"
        } else if score >= 0.4 {
            return "Fair (Usable)"
        } else {
            return "Poor Quality"
        }
    }

    private func metricQualityLabel(for score: Double) -> String {
        if score >= 0.75 {
            return "Good"
        } else if score >= 0.4 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    private func normalizedBlurScore(_ blur: Double) -> Double {
        min(1.0, blur / 500.0)
    }

    private func normalizedBrightnessScore(_ brightness: Double) -> Double {
        let penalty = abs(brightness - 0.5) * 2
        return max(0.0, min(1.0, 1.0 - penalty))
    }
}

// MARK: - Compact Image Review

/// Inline review component for use within capture flows
struct CompactImageReview: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Image thumbnail
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .elevation(.lg)

            // Actions
            HStack(spacing: Spacing.md) {
                Button {
                    onRetake()
                } label: {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.secondary)

                Button {
                    onUse()
                } label: {
                    Label("Use Photo", systemImage: "checkmark")
                }
                .buttonStyle(.primary)
            }
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Image Review") {
    ImageReviewView(
        image: UIImage(systemName: "doc.text") ?? UIImage(),
        qualityResult: ImageQualityAnalyzer.QualityResult(
            overallScore: 0.85,
            blurScore: 0.85,
            brightnessScore: 0.72,
            textConfidence: 0.90,
            textRegionCount: 12,
            issues: [.tooBlurry(advice: "Hold steady")],
            isAcceptable: true
        ),
        isQualityFeedbackUnavailable: false,
        book: Book(title: "Test Book", author: "Test Author"),
        onRetake: {},
        onConfirm: {}
    )
}

#Preview("Compact Review") {
    CompactImageReview(
        image: UIImage(systemName: "doc.text.fill") ?? UIImage(),
        onRetake: {},
        onUse: {}
    )
    .padding()
}
