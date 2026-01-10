import SwiftUI

// MARK: - LoadingOverlay

/// Full-screen loading overlay with message.
struct LoadingOverlay: View {

    // MARK: - Properties

    let message: String

    /// Progress value (0-1) for determinate progress
    var progress: Double?

    /// Style variant
    var style: Style = .default

    // MARK: - Styles

    enum Style {
        case `default`  // Centered spinner with message
        case fullScreen // Covers entire screen with dimming
        case card       // Compact card style
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .default:
            defaultStyle
        case .fullScreen:
            fullScreenStyle
        case .card:
            cardStyle
        }
    }

    // MARK: - Default Style

    private var defaultStyle: some View {
        VStack(spacing: Spacing.md) {
            progressIndicator
                .scaleEffect(1.2)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
    }

    // MARK: - Full Screen Style

    private var fullScreenStyle: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                progressIndicator
                    .scaleEffect(1.5)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.xl)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        HStack(spacing: Spacing.md) {
            progressIndicator

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Progress Indicator

    @ViewBuilder
    private var progressIndicator: some View {
        if let progress = progress {
            ProgressView(value: progress)
                .progressViewStyle(CircularProgressViewStyle())
        } else {
            ProgressView()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply a loading overlay conditionally
    func loadingOverlay(
        isPresented: Bool,
        message: String = "Loading...",
        style: LoadingOverlay.Style = .fullScreen
    ) -> some View {
        ZStack {
            self

            if isPresented {
                LoadingOverlay(message: message, style: style)
            }
        }
    }
}

// MARK: - LoadingButton

/// Button that shows loading state when action is in progress.
struct LoadingButton<Label: View>: View {

    // MARK: - Properties

    let action: () async -> Void
    @ViewBuilder let label: () -> Label

    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        Button {
            guard !isLoading else { return }
            isLoading = true
            Task {
                await action()
                isLoading = false
            }
        } label: {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                label()
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        Text("Default Style").font(.headline)
        LoadingOverlay(message: "Loading quotes...")
            .frame(height: 100)

        Divider()

        Text("Card Style").font(.headline)
        LoadingOverlay(message: "Syncing...", style: .card)
            .padding(.horizontal)

        Divider()

        Text("With Progress").font(.headline)
        LoadingOverlay(message: "Uploading...", progress: 0.65)
            .frame(height: 100)

        Divider()

        Text("Full Screen (tap to see)").font(.headline)
        Text("Full screen covers entire view")
            .frame(height: 100)
            .loadingOverlay(isPresented: false, message: "Processing...")
    }
}
