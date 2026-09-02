import SwiftUI

struct ExtractionReviewProcessingView: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    let isProcessing: Bool
    let onPoll: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.gildedAccent)
                .frame(width: 36, height: 36)

            Text("Reading your page…")
                .font(.serifHeadline)
                .foregroundStyle(Color.textPrimary)

            if totalCount > 1 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Color.gildedAccent)
                    .frame(width: 200)
            }

            Text("\(completedCount) of \(totalCount) pages complete")
                .font(.uiCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
        .task(id: isProcessing) {
            guard isProcessing else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(500))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                onPoll()
            }
        }
    }
}

struct ExtractionReviewNoQuotesView: View {
    let onAddManualQuote: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "text.quote")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(Color.gildedAccent)
                .frame(width: 36, height: 36)

            Text("No marked passages found")
                .font(.serifHeadline)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("You can add a passage yourself, or close and recapture the page.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            Button(action: onAddManualQuote) {
                Text("Add manually")
                    .font(.uiLabel)
                    .foregroundStyle(Color.darkLinen)
                    .frame(minHeight: 44)
                    .padding(.horizontal, Spacing.lg)
                    .background(LinearGradient.foilAccent, in: Capsule())
            }
            .buttonStyle(.plain)

            Button("Close", action: onClose)
                .font(.uiLabel)
                .foregroundStyle(Color.brand)
                .frame(minHeight: 44)
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
    }
}

struct ExtractionReviewFailureView: View {
    let primaryFailureMessage: String?
    let onRetry: () -> Void
    let onUseOnDevice: () -> Void
    let onAddManualQuote: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(Color.gildedAccent)
                .frame(width: 36, height: 36)

            Text(primaryFailureMessage ?? "The captured page could not be processed.")
                .font(.serifHeadline)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Try again with a clear photo, or add the passage manually if the marked text is readable.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            Button(action: onRetry) {
                Text("Retry AI")
                    .font(.uiLabel)
                    .foregroundStyle(Color.darkLinen)
                    .frame(minHeight: 44)
                    .padding(.horizontal, Spacing.lg)
                    .background(LinearGradient.foilAccent, in: Capsule())
            }
            .buttonStyle(.plain)

            Button("Use on-device", action: onUseOnDevice)
                .font(.uiLabel)
                .foregroundStyle(Color.brand)
                .frame(minHeight: 44)
                .buttonStyle(.plain)

            Button("Add manually", action: onAddManualQuote)
                .font(.uiLabel)
                .foregroundStyle(Color.brand)
                .frame(minHeight: 44)
                .buttonStyle(.plain)

            Button("Close", action: onClose)
                .font(.uiLabel)
                .foregroundStyle(Color.brand)
                .frame(minHeight: 44)
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .background(Color.backgroundPrimary)
    }
}
