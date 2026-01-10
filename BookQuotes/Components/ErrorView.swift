import SwiftUI

// MARK: - ErrorView

/// Full-screen error view with retry option.
struct ErrorView: View {

    // MARK: - Properties

    let error: Error

    /// Optional retry action
    var retryAction: (() -> Void)?

    /// Style variant
    var style: Style = .default

    // MARK: - Styles

    enum Style {
        case `default`  // Warning triangle, centered
        case critical   // Red styling for critical errors
        case gentle     // Softer styling for recoverable issues
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 50))
                .foregroundStyle(iconColor)

            // Title
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Error description
            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Retry button
            if let retry = retryAction {
                Button("Try Again") {
                    retry()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
struct ErrorBanner: View {

    // MARK: - Properties

    let message: String
    let onDismiss: () -> Void

    /// Optional action button
    var onAction: (() -> Void)?
    var actionLabel: String = "Fix"

    /// Style variant
    var style: Style = .error

    // MARK: - Styles

    enum Style {
        case error      // Red background
        case warning    // Orange/amber background
        case info       // Blue background
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Icon
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
                    action()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            }

            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(Spacing.md)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .padding(.horizontal)
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
