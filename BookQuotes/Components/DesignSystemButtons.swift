import SwiftUI

// MARK: - Button Styles

/// Base pressable button style with scale, opacity, and haptic feedback.
/// Use directly for simple buttons or as a building block for semantic styles.
struct PressableButtonStyle: ButtonStyle {

    /// Scale factor when pressed (default: 0.97)
    var scale: CGFloat = 0.97

    /// Whether to trigger haptic feedback on press
    var enableHaptic: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && enableHaptic {
                    HapticManager.light()
                }
            }
    }
}

/// Primary action button style - filled background, prominent appearance.
/// Use for main CTAs: "Save", "Continue", "Add Book"
struct PrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isEnabled ? Color.brand : Color.brand.opacity(0.5))
            )
            .elevation(configuration.isPressed ? .xs : .sm, colorScheme: colorScheme)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.medium()
                }
            }
    }
}

/// Secondary action button style - bordered, less prominent.
/// Use for secondary actions: "Cancel", "Skip", "Edit"
struct SecondaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.brand : Color.brand.opacity(0.5))
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isEnabled ? Color.brand : Color.brand.opacity(0.5), lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(configuration.isPressed ? Color.brand.opacity(0.08) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.light()
                }
            }
    }
}

/// Destructive action button style - red tinted for dangerous actions.
/// Use for: "Delete", "Remove", "Discard"
struct DestructiveButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isEnabled ? Color.error : Color.error.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.warning()
                }
            }
    }
}

/// Ghost button style - minimal, text-only appearance.
/// Use for tertiary actions: "Learn more", "View all"
struct GhostButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isEnabled ? Color.brand : Color.brand.opacity(0.5))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(configuration.isPressed ? Color.brand.opacity(0.08) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.light()
                }
            }
    }
}

/// Icon button style - for toolbar/navigation icons.
/// Use for icon-only buttons: back, close, share
struct IconButtonStyle: ButtonStyle {

    /// Icon size category
    enum Size {
        case small, medium, large

        var padding: CGFloat {
            switch self {
            case .small: return Spacing.xs
            case .medium: return Spacing.sm
            case .large: return Spacing.md
            }
        }
    }

    var size: Size = .medium

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(size.padding)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.backgroundSecondary : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.light()
                }
            }
    }
}

// MARK: - ButtonStyle Extensions

extension ButtonStyle where Self == PressableButtonStyle {
    /// Basic pressable button with scale feedback and haptics
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Primary CTA button - filled brand color
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// Secondary button - bordered outline
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    /// Destructive action button - red/error color
    static var destructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

extension ButtonStyle where Self == GhostButtonStyle {
    /// Ghost/text button - minimal appearance
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

extension ButtonStyle where Self == IconButtonStyle {
    /// Icon button with circular hit area
    static var icon: IconButtonStyle { IconButtonStyle() }

    /// Small icon button
    static var iconSmall: IconButtonStyle { IconButtonStyle(size: .small) }

    /// Large icon button
    static var iconLarge: IconButtonStyle { IconButtonStyle(size: .large) }
}
