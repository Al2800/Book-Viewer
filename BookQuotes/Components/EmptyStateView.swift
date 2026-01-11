import SwiftUI

// MARK: - EmptyStateView

/// Reusable empty state view with icon, title, message, and optional action.
/// Features Stripe-level polish: staggered entrance animations, icon effects, and brand personality.
struct EmptyStateView: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let message: String

    /// Optional action button
    var action: (label: String, handler: () -> Void)?

    /// Style variant
    var style: Style = .default

    // MARK: - State

    @State private var iconAppeared = false
    @State private var titleAppeared = false
    @State private var messageAppeared = false
    @State private var buttonAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Styles

    enum Style {
        case `default`  // Centered, large icon
        case compact    // Smaller, inline
        case card       // With background card
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .default:
            defaultStyle
        case .compact:
            compactStyle
        case .card:
            cardStyle
        }
    }

    // MARK: - Entrance Animation

    private func triggerEntranceAnimation() {
        guard !reduceMotion else {
            iconAppeared = true
            titleAppeared = true
            messageAppeared = true
            buttonAppeared = true
            return
        }

        withAnimation(.smoothSpring) {
            iconAppeared = true
        }
        withAnimation(.smoothSpring.delay(0.1)) {
            titleAppeared = true
        }
        withAnimation(.smoothSpring.delay(0.2)) {
            messageAppeared = true
        }
        withAnimation(.smoothSpring.delay(0.3)) {
            buttonAppeared = true
        }
    }

    // MARK: - Default Style

    private var defaultStyle: some View {
        VStack(spacing: Spacing.lg) {
            // Animated icon with gentle bounce
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Color.accent.opacity(0.7))
                .symbolEffect(.bounce, options: .speed(0.5), isActive: iconAppeared && !reduceMotion)
                .opacity(iconAppeared ? 1 : 0)
                .scaleEffect(iconAppeared ? 1 : 0.5)

            // Title with slide up
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 15)

            // Message with fade
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(messageAppeared ? 1 : 0)
                .offset(y: messageAppeared ? 0 : 10)

            // Action button with our primary style
            if let action = action {
                Button(action.label) {
                    HapticManager.light()
                    action.handler()
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

    // MARK: - Compact Style

    private var compactStyle: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accent.opacity(0.6))
                .opacity(iconAppeared ? 1 : 0)
                .scaleEffect(iconAppeared ? 1 : 0.8)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .opacity(titleAppeared ? 1 : 0)
            .offset(x: titleAppeared ? 0 : -10)

            Spacer()

            if let action = action {
                Button(action.label) {
                    HapticManager.light()
                    action.handler()
                }
                .buttonStyle(.ghost)
                .opacity(buttonAppeared ? 1 : 0)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.backgroundSecondary.opacity(0.5))
        )
        .onAppear {
            triggerEntranceAnimation()
        }
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.accent.opacity(0.7))
                .symbolEffect(.pulse, options: .repeating.speed(0.3), isActive: iconAppeared && !reduceMotion)
                .opacity(iconAppeared ? 1 : 0)
                .scaleEffect(iconAppeared ? 1 : 0.6)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 10)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(messageAppeared ? 1 : 0)

            if let action = action {
                Button(action.label) {
                    HapticManager.light()
                    action.handler()
                }
                .buttonStyle(.secondary)
                .opacity(buttonAppeared ? 1 : 0)
                .scaleEffect(buttonAppeared ? 1 : 0.95)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.sm, colorScheme: colorScheme)
        .onAppear {
            triggerEntranceAnimation()
        }
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            Text("Default Style (Animated)")
                .font(.headline)
            EmptyStateView(
                icon: "books.vertical",
                title: "No Books Yet",
                message: "Capture your first book cover to start building your library.",
                action: ("Add Book", { print("Action tapped") })
            )
            .frame(height: 300)

            Divider()

            Text("Compact Style")
                .font(.headline)
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                message: "Try different search terms",
                action: ("Clear Filters", { print("Clear") }),
                style: .compact
            )
            .padding(.horizontal)

            Divider()

            Text("Card Style (With Pulse)")
                .font(.headline)
            EmptyStateView(
                icon: "quote.opening",
                title: "No Quotes",
                message: "Capture some pages to add quotes to this book.",
                action: ("Capture Pages", { print("Capture") }),
                style: .card
            )
            .padding(.horizontal)

            Divider()

            Text("Without Action")
                .font(.headline)
            EmptyStateView(
                icon: "wifi.slash",
                title: "You're Offline",
                message: "Some features require an internet connection.",
                style: .card
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color.backgroundPrimary)
}
