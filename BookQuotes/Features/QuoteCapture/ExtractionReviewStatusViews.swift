import SwiftUI

struct ExtractionReviewProcessingView: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    let isProcessing: Bool
    let onPoll: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)

                VStack(spacing: Spacing.sm) {
                    Text("Processing Pages")
                        .font(.headline)

                    Text("Extracting quotes from your captured pages...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                        .padding(.top, Spacing.md)

                    Text("\(completedCount) of \(totalCount) pages complete")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(Spacing.xl)
            .paperCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: isProcessing) {
            guard isProcessing else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(500))
                } catch {
                    // A state change or dismissal cancels this task. Return rather than
                    // swallowing cancellation and spinning in a tight polling loop.
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
        ContentUnavailableView {
            Label("No Quotes Found", systemImage: "text.quote")
        } description: {
            Text("No marked passages were detected in the captured pages. You can add quotes manually or try recapturing with clearer markings.")
        } actions: {
            ExtractionReviewFallbackActions(
                onAddManualQuote: onAddManualQuote,
                onClose: onClose
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExtractionReviewFailureView: View {
    let primaryFailureMessage: String?
    let onRetry: () -> Void
    let onUseOnDevice: () -> Void
    let onAddManualQuote: () -> Void
    let onClose: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Extraction Failed", systemImage: "exclamationmark.triangle")
        } description: {
            VStack(spacing: Spacing.sm) {
                Text(primaryFailureMessage ?? "The captured page could not be processed.")
                Text("Try again with a clear photo, or add the quote manually if the marked text is readable.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        } actions: {
            VStack(spacing: Spacing.md) {
                Button {
                    onRetry()
                } label: {
                    Label("Retry AI Extraction", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.primaryCompact)

                Button {
                    onUseOnDevice()
                } label: {
                    Label("Use On-Device Instead", systemImage: "iphone")
                }
                .buttonStyle(.secondaryCompact)

                ExtractionReviewFallbackActions(
                    onAddManualQuote: onAddManualQuote,
                    onClose: onClose
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExtractionReviewNoSelectionView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Select a Page", systemImage: "doc.text.viewfinder")
        } description: {
            Text("Choose a page from the left to review its extracted quotes")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ExtractionReviewFallbackActions: View {
    let onAddManualQuote: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Button {
                onAddManualQuote()
            } label: {
                Label("Add Quote Manually", systemImage: "plus")
            }
            .buttonStyle(.primaryCompact)

            Button {
                onClose()
            } label: {
                Text("Close")
            }
            .buttonStyle(.secondaryCompact)
        }
    }
}
