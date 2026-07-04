import SwiftUI

/// A delightful heart button with burst particle animation for favoriting.
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
    @State private var showParticles = false
    @State private var particleScale: CGFloat = 0

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Constants

    private let particleCount = 6
    private let particleSize: CGFloat = 6
    private let burstDistance: CGFloat = 20

    // MARK: - Body

    var body: some View {
        Button {
            toggleFavorite()
        } label: {
            ZStack {
                // Particle burst layer (behind heart)
                if showParticles && !reduceMotion {
                    particleBurst
                }

                // Heart icon
                heartIcon
            }
            .frame(width: size + burstDistance, height: size + burstDistance)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Heart Icon

    private var heartIcon: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .font(.system(size: size))
            .foregroundStyle(isFavorite ? Color.accent : Color.textSecondary)
            .scaleEffect(scale)
            .animation(reduceMotion ? nil : .microBounce, value: scale)
    }

    // MARK: - Particle Burst

    private var particleBurst: some View {
        ForEach(0..<particleCount, id: \.self) { index in
            Circle()
                .fill(particleColor(for: index))
                .frame(width: particleSize, height: particleSize)
                .offset(particleOffset(for: index))
                .opacity(particleOpacity)
                .scaleEffect(particleScale)
        }
    }

    private func particleColor(for index: Int) -> Color {
        // Alternate between accent gold and brand for variety
        index % 2 == 0 ? .accent : .brand
    }

    private func particleOffset(for index: Int) -> CGSize {
        let angle = (CGFloat(index) / CGFloat(particleCount)) * .pi * 2
        let distance = showParticles ? burstDistance : 0
        return CGSize(
            width: cos(angle) * distance,
            height: sin(angle) * distance
        )
    }

    private var particleOpacity: Double {
        showParticles ? 0 : 1
    }

    // MARK: - Actions

    private func toggleFavorite() {
        let wasFavorite = isFavorite
        isFavorite.toggle()

        if isFavorite && !wasFavorite {
            // Favoriting: show celebration
            animateFavorite()
        } else {
            // Unfavoriting: subtle feedback only
            animateUnfavorite()
        }

        // Trigger haptic
        HapticManager.favoriteToggled()

        // Call completion handler
        onToggle?()
    }

    private func animateFavorite() {
        if reduceMotion {
            // Reduce Motion: instant state change, no particles
            return
        }

        // Scale up with bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            scale = 1.3
            showParticles = true
            particleScale = 1
        }

        // Animate particles outward and fade
        withAnimation(.easeOut(duration: 0.4)) {
            particleScale = 0.5
        }

        // Reset scale
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)) {
            scale = 1.0
        }

        // Clean up particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showParticles = false
            particleScale = 0
        }
    }

    private func animateUnfavorite() {
        if reduceMotion { return }

        // Subtle shrink and return
        withAnimation(.quickSpring) {
            scale = 0.8
        }
        withAnimation(.quickSpring.delay(0.05)) {
            scale = 1.0
        }
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
