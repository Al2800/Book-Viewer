import SwiftUI

/// A quiet heart button for favoriting with a gentle scale acknowledgment.
/// Provides visual and haptic feedback when toggling favorite state.
///
/// Usage:
/// ```swift
/// HeartBurstButton(isFavorite: $quote.isFavorite) {
///     // Save changes
/// }
/// ```
struct HeartBurstButton: View {
    // MARK: - Properties

    /// Binding to the favorite state
    @Binding var isFavorite: Bool

    /// Optional action to perform after toggling (e.g., save to database)
    var onToggle: (() -> Void)?

    /// Size of the heart icon
    var size: CGFloat = 24

    // MARK: - State

    @State private var scale: CGFloat = 1.0

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        Button {
            toggleFavorite()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: size))
                .foregroundStyle(isFavorite ? Color.accent : Color.textSecondary)
                .scaleEffect(scale)
                .animation(reduceMotion ? nil : .microBounce, value: scale)
                .frame(width: size + 12, height: size + 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Actions

    private func toggleFavorite() {
        isFavorite.toggle()

        if !reduceMotion {
            // Gentle press acknowledgment
            withAnimation(.quickSpring) {
                scale = isFavorite ? 1.15 : 0.9
            }
            withAnimation(.quickSpring.delay(0.1)) {
                scale = 1.0
            }
        }

        // Trigger haptic
        HapticManager.favoriteToggled()

        // Call completion handler
        onToggle?()
    }
}

// MARK: - Previews

#Preview("Favorite Button States") {
    HStack(spacing: 40) {
        VStack {
            HeartBurstButton(isFavorite: .constant(false))
            Text("Not Favorite")
                .font(.caption)
        }

        VStack {
            HeartBurstButton(isFavorite: .constant(true))
            Text("Favorite")
                .font(.caption)
        }
    }
    .padding()
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var isFavorite = false

        var body: some View {
            VStack(spacing: 20) {
                HeartBurstButton(isFavorite: $isFavorite) {
                    print("Favorite toggled: \(isFavorite)")
                }

                Text(isFavorite ? "Favorited!" : "Tap to favorite")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return InteractivePreview()
}

#Preview("Different Sizes") {
    HStack(spacing: 30) {
        HeartBurstButton(isFavorite: .constant(true), size: 16)
        HeartBurstButton(isFavorite: .constant(true), size: 24)
        HeartBurstButton(isFavorite: .constant(true), size: 32)
    }
    .padding()
}
