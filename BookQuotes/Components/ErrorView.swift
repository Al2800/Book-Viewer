import SwiftUI

// MARK: - ErrorView

/// Full-screen error view with retry option.
/// Features Stripe-level polish: staggered entrance, icon animation, clear recovery actions.
struct ErrorView: View {

    // MARK: - Properties

    let error: Error

    /// Optional retry action
    var retryAction: (() -> Void)?

    /// Style variant
    var style: Style = .default

    // MARK: - State

    @State private var iconAppeared = false
    @State private var textAppeared = false
    @State private var buttonAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Styles

    enum Style {
        case `default`  // Warning triangle, centered
        case critical   // Red styling for critical errors
        case gentle     // Softer styling for recoverable issues
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon with shake animation for errors
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundStyle(iconColor)
                .symbolEffect(.bounce, options: .speed(0.5), isActive: iconAppeared && style == .critical && !reduceMotion)
                .opacity(iconAppeared ? 1 : 0)
                .scaleEffect(iconAppeared ? 1 : 0.5)

            // Title
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 10)

            // Error description
            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 8)

            // Retry button with primary style
            if let retry = retryAction {
                Button("Try Again") {
                    HapticManager.medium()
                    retry()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)
                .opacity(buttonAppeared ? 1 : 0)
                .scaleEffect(buttonAppeared ? 1 : 0.9)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            triggerEntranceAnimation()
        }
    }

    // MARK: - Entrance Animation

    private func triggerEntranceAnimation() {
        // Haptic for error notification
        if style == .critical {
            HapticManager.error()
        } else if style == .default {
            HapticManager.warning()
        }

        guard !reduceMotion else {
            iconAppeared = true
            textAppeared = true
            buttonAppeared = true
            return
        }

        withAnimation(.smoothSpring) {
            iconAppeared = true
        }
        withAnimation(.smoothSpring.delay(0.15)) {
            textAppeared = true
        }
        withAnimation(.smoothSpring.delay(0.3)) {
            buttonAppeared = true
        }
    }

    // MARK: - Computed

    private var iconName: String {
        switch style {
        case .default: return "exclamationmark.triangle"
        case .critical: return "xmark.circle"
        case .gentle: return "info.circle"
        }
    }

    private var iconColor: Color {
        switch style {
        case .default: return .warning
        case .critical: return .error
        case .gentle: return .secondary
        }
    }

    private var title: String {
        switch style {
        case .default: return "Something went wrong"
        case .critical: return "An error occurred"
        case .gentle: return "Couldn't complete action"
        }
    }
}

// MARK: - ErrorBanner

/// Dismissable inline error banner with optional action.
/// Features slide-in animation and haptic feedback.
struct ErrorBanner: View {

    // MARK: - Properties

    let message: String
    let onDismiss: () -> Void

    /// Optional action button
    var onAction: (() -> Void)?
    var actionLabel: String = "Fix"

    /// Style variant
    var style: Style = .error

    // MARK: - State

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Styles

    enum Style {
        case error      // Red background
        case warning    // Orange/amber background
        case info       // Blue background
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconName)
                .foregroundStyle(.white)

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer()

            // Action button
            if let action = onAction {
                Button(actionLabel) {
                    HapticManager.light()
                    action()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }

            // Dismiss button
            Button {
                HapticManager.light()
                withAnimation(.quickSpring) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(Spacing.xs)
                    .background(Circle().fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.md, colorScheme: colorScheme)
        .padding(.horizontal)
        // Slide-in animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : -20)
        .onAppear {
            // Haptic based on style
            switch style {
            case .error: HapticManager.error()
            case .warning: HapticManager.warning()
            case .info: HapticManager.light()
            }

            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
        // Exit transition
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }

    // MARK: - Computed

    private var iconName: String {
        switch style {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .error: return .error
        case .warning: return .warning
        case .info: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 32) {
        Text("Error View").font(.headline)
        ErrorView(
            error: NSError(
                domain: "com.bookquotes",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load data from the server."]
            ),
            retryAction: { print("Retry") }
        )
        .frame(height: 250)

        Divider()

        Text("Error Banners").font(.headline)
        ErrorBanner(
            message: "Failed to save quote",
            onDismiss: {},
            onAction: { print("Fix") }
        )

        ErrorBanner(
            message: "No internet connection",
            onDismiss: {},
            style: .warning
        )

        ErrorBanner(
            message: "Sync in progress",
            onDismiss: {},
            style: .info
        )
    }
}
