import SwiftUI

// MARK: - Animations

extension Animation {
    // MARK: - Spring Animations (existing)

    /// Smooth spring animation for general transitions
    static var smoothSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    /// Quick spring animation for responsive feedback
    static var quickSpring: Animation {
        .spring(response: 0.25, dampingFraction: 0.75)
    }

    // MARK: - NEW: Micro-interactions

    /// Micro bounce for button press feedback - very snappy
    static var microBounce: Animation {
        .spring(response: 0.15, dampingFraction: 0.6)
    }

    // MARK: - NEW: Entrance Animations

    /// Standard entrance animation for most views
    static var entrance: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }

    /// Snappy state change animation for toggles, selection changes
    static var snappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.9)
    }

    /// Gentle easing for subtle, calming motion
    static var gentle: Animation {
        .easeInOut(duration: 0.5)
    }

    // MARK: - NEW: Staggered List Animations

    /// Staggered animation for list items
    /// - Parameters:
    ///   - index: The item's index in the list
    ///   - baseDelay: Delay increment per item (default 0.05s)
    /// - Returns: Animation with appropriate delay
    static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
        .delay(Double(index) * baseDelay)
    }

    /// Fast stagger for quick list appearance
    static func fastStagger(index: Int) -> Animation {
        .spring(response: 0.25, dampingFraction: 0.8)
        .delay(Double(index) * 0.03)
    }

    // MARK: - Accessibility-Aware Animations

    /// Returns nil if user prefers reduced motion, otherwise returns self.
    /// Use with `.animation()` which accepts optional Animation.
    var accessibilityAware: Animation? {
        AccessibilityManager.shared.prefersReducedMotion ? nil : self
    }

    /// Returns an instant transition if reduced motion is enabled, otherwise returns the animation.
    /// Use when you need an Animation rather than optional.
    static func accessible(_ animation: Animation) -> Animation {
        AccessibilityManager.shared.prefersReducedMotion ? .linear(duration: 0) : animation
    }

    /// Accessible version of smoothSpring
    static var accessibleSmoothSpring: Animation {
        accessible(.smoothSpring)
    }

    /// Accessible version of entrance
    static var accessibleEntrance: Animation {
        accessible(.entrance)
    }
}

// MARK: - Transitions

extension AnyTransition {
    // MARK: - Existing Transitions

    /// Quote card appearance transition
    static var quoteCard: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        )
    }

    /// Slide up from bottom transition
    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    // MARK: - NEW: Fade Transitions

    /// Fade with subtle scale - most common entrance effect
    static var fadeScale: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.95))
    }

    /// Pure fade for simple transitions
    static var fade: AnyTransition {
        .opacity
    }

    // MARK: - NEW: Slide Transitions

    /// Slide from bottom with fade - for sheets and modals
    static var slideFromBottom: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    /// Navigation push transition (trailing to leading)
    static var push: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Navigation pop transition (leading to trailing)
    static var pop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// Slide from top - for dropdown menus
    static var slideFromTop: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
}

// MARK: - Animation View Modifiers

extension View {
    /// Apply standard entrance animation
    /// - Parameters:
    ///   - appeared: Binding to control animation trigger
    ///   - delay: Optional delay before animation starts
    func entranceAnimation(appeared: Bool, delay: Double = 0) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)
            .animation(.entrance.delay(delay), value: appeared)
    }

    /// Apply staggered entrance for list items
    /// - Parameters:
    ///   - appeared: Binding to control animation trigger
    ///   - index: Item index for stagger calculation
    func staggeredEntrance(appeared: Bool, index: Int) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.staggered(index: index), value: appeared)
    }

    // MARK: - Accessibility-Aware Animation Modifiers

    /// Apply animation only if Reduce Motion is disabled.
    /// Falls back to instant transition when Reduce Motion is enabled.
    /// - Parameters:
    ///   - animation: The animation to apply when Reduce Motion is off
    ///   - value: The value to animate
    func accessibleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(
            AccessibilityManager.shared.prefersReducedMotion ? nil : animation,
            value: value
        )
    }

    /// Entrance animation that respects Reduce Motion preference.
    /// Shows fade-only when Reduce Motion is enabled, full animation otherwise.
    /// - Parameters:
    ///   - appeared: Controls the animation state
    ///   - delay: Optional delay before animation starts
    @ViewBuilder
    func accessibleEntrance(appeared: Bool, delay: Double = 0) -> some View {
        if AccessibilityManager.shared.prefersReducedMotion {
            // Reduce Motion: instant opacity change only
            self.opacity(appeared ? 1 : 0)
        } else {
            // Full animation: opacity + scale with spring
            self
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.95)
                .animation(.entrance.delay(delay), value: appeared)
        }
    }

    /// Staggered entrance that respects Reduce Motion preference.
    /// Shows instant appearance when Reduce Motion is enabled.
    /// - Parameters:
    ///   - appeared: Controls the animation state
    ///   - index: Item index for stagger delay calculation
    @ViewBuilder
    func accessibleStaggeredEntrance(appeared: Bool, index: Int) -> some View {
        if AccessibilityManager.shared.prefersReducedMotion {
            // Reduce Motion: instant opacity change
            self.opacity(appeared ? 1 : 0)
        } else {
            // Full animation: opacity + offset with staggered delay
            self
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.staggered(index: index), value: appeared)
        }
    }

    // MARK: - Error Shake Animation

    /// Apply a shake animation to indicate validation error.
    /// Respects Reduce Motion accessibility preference.
    /// - Parameters:
    ///   - shakeCount: Number of times to shake back and forth (default 3)
    ///   - shakeOffset: Maximum horizontal offset in points (default 10)
    /// - Returns: Modified view with shake animation applied
    func shake(trigger: Int, shakeCount: Int = 3, shakeOffset: CGFloat = 10) -> some View {
        modifier(ShakeModifier(trigger: trigger, shakeCount: shakeCount, shakeOffset: shakeOffset))
    }
}

// MARK: - Shake Modifier

/// View modifier that applies a horizontal shake animation.
/// Used for validation errors and invalid input feedback.
private struct ShakeModifier: ViewModifier {
    let trigger: Int
    let shakeCount: Int
    let shakeOffset: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(shakeCount: shakeCount, shakeOffset: shakeOffset, animatableData: CGFloat(trigger)))
            .animation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.3), value: trigger)
    }
}

/// Animatable effect that produces the shake motion.
private struct ShakeEffect: GeometryEffect {
    var shakeCount: Int
    var shakeOffset: CGFloat
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * CGFloat(shakeCount)) * shakeOffset
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}
