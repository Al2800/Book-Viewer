import SwiftUI

// MARK: - LoadingOverlay

/// Full-screen loading overlay with message.
/// Features Stripe-level polish: branded spinner, entrance animation, progress states.
struct LoadingOverlay: View {

    // MARK: - Properties

    let message: String

    /// Progress value (0-1) for determinate progress
    var progress: Double?

    /// Style variant
    var style: Style = .default

    // MARK: - State

    @State private var hasAppeared = false
    @State private var rotation: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

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
                .contentTransition(.numericText())
        }
        .padding(Spacing.xl)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Full Screen Style

    private var fullScreenStyle: some View {
        ZStack {
            // Scrim with semantic overlay opacity
            Color.scrim(.light)
                .ignoresSafeArea()
                .opacity(hasAppeared ? 1 : 0)

            VStack(spacing: Spacing.md) {
                progressIndicator
                    .scaleEffect(1.5)

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .padding(Spacing.xl)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .elevation(.lg, colorScheme: colorScheme)
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.85)
        }
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        HStack(spacing: Spacing.md) {
            progressIndicator

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.sm, colorScheme: colorScheme)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Progress Indicator

    @ViewBuilder
    private var progressIndicator: some View {
        if let progress = progress {
            // Determinate progress with branded colors
            ZStack {
                Circle()
                    .stroke(Color.brand.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.brand, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? .none : .smoothSpring, value: progress)
            }
            .frame(width: 32, height: 32)
        } else {
            // Indeterminate spinner with brand color
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .brand))
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
/// Features smooth transition between loading and ready states.
struct LoadingButton<Label: View>: View {

    // MARK: - Properties

    let action: () async -> Void
    @ViewBuilder let label: () -> Label

    /// Use primary button style
    var isPrimary: Bool = true

    @State private var isLoading = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        Button {
            guard !isLoading else { return }
            HapticManager.light()
            isLoading = true
            Task {
                await action()
                withAnimation(reduceMotion ? .none : .smoothSpring) {
                    isLoading = false
                }
            }
        } label: {
            ZStack {
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isPrimary ? .white : .brand))
                    .opacity(isLoading ? 1 : 0)
                    .scaleEffect(isLoading ? 1 : 0.5)

                // Label
                label()
                    .opacity(isLoading ? 0 : 1)
                    .scaleEffect(isLoading ? 0.8 : 1)
            }
            .animation(reduceMotion ? .none : .smoothSpring, value: isLoading)
        }
        .buttonStyle(.pressable)
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
