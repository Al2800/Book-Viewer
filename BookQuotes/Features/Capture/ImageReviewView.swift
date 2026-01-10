import SwiftUI

// MARK: - Image Review View

/// Sheet view for reviewing a captured image before processing.
/// Allows user to retake or confirm the photo.
struct ImageReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let qualityResult: ImageQualityAnalyzer.QualityResult?
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

                // Quality feedback
                if let result = qualityResult {
                    qualitySection(result)
                }

                // Action buttons
                actionButtons
            }
            .background(Color.black)
            .navigationTitle("Review Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
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
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Quality Section

    private func qualitySection(_ result: ImageQualityAnalyzer.QualityResult) -> some View {
        VStack(spacing: Spacing.sm) {
            // Quality bar
            HStack(spacing: Spacing.md) {
                // Overall score
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(qualityColor(for: result.overallScore))
                        .frame(width: 10, height: 10)

                    Text(qualityLabel(for: result.overallScore))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }

                Spacer()

                // Individual metrics
                HStack(spacing: Spacing.md) {
                    metricIndicator(label: "Blur", score: result.blurScore)
                    metricIndicator(label: "Light", score: result.brightnessScore)
                    metricIndicator(label: "Text", score: result.textConfidence)
                }
            }
            .padding(Spacing.md)
            .background(Color.black.opacity(0.7))

            // Warnings if any
            if !result.issues.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(result.issues.prefix(2), id: \.rawValue) { issue in
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.warning)

                            Text(issue.advice)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private func metricIndicator(label: String, score: Double) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))

            Circle()
                .fill(qualityColor(for: score))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.lg) {
            // Retake button
            Button {
                onRetake()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Retake")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            // Use photo button
            Button {
                onConfirm()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Use Photo")
                }
                .font(.headline)
                .foregroundStyle(shouldShowWarning ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(shouldShowWarning ? Color.warning : Color.brand)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
        }
        .padding(Spacing.lg)
        .background(Color.black)
    }

    // MARK: - Helpers

    private var shouldShowWarning: Bool {
        guard let result = qualityResult else { return false }
        return result.overallScore < 0.6
    }

    private func qualityColor(for score: Double) -> Color {
        if score >= 0.8 {
            return .success
        } else if score >= 0.6 {
            return .warning
        } else {
            return .error
        }
    }

    private func qualityLabel(for score: Double) -> String {
        if score >= 0.8 {
            return "Good Quality"
        } else if score >= 0.6 {
            return "Acceptable"
        } else {
            return "Poor Quality"
        }
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
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            // Actions
            HStack(spacing: Spacing.md) {
                Button {
                    onRetake()
                } label: {
                    Label("Retake", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onUse()
                } label: {
                    Label("Use Photo", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
            }
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Preview

#Preview("Image Review") {
    ImageReviewView(
        image: UIImage(systemName: "doc.text")!,
        qualityResult: ImageQualityAnalyzer.QualityResult(
            blurScore: 0.85,
            brightnessScore: 0.72,
            textConfidence: 0.90,
            textBlockCount: 12,
            issues: [.slightlyBlurry]
        ),
        book: Book(title: "Test Book", author: "Test Author"),
        onRetake: {},
        onConfirm: {}
    )
}

#Preview("Compact Review") {
    CompactImageReview(
        image: UIImage(systemName: "doc.text.fill")!,
        onRetake: {},
        onUse: {}
    )
    .padding()
}
