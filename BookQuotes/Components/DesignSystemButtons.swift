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
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1.0)
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

    /// Compact buttons hug their content for inline placement;
    /// non-compact buttons fill the available width for full-width CTAs.
    var compact: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.uiLabel)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? Spacing.md : Spacing.lg)
            .padding(.vertical, compact ? Spacing.sm : Spacing.md)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isEnabled ? Color.brand : Color.brand.opacity(0.5))
            )
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
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

    /// Compact buttons hug their content for inline placement;
    /// non-compact buttons fill the available width.
    var compact: Bool = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.uiLabel)
            .foregroundStyle(isEnabled ? Color.actionForeground : Color.actionForeground.opacity(0.5))
            .padding(.horizontal, compact ? Spacing.md : Spacing.lg)
            .padding(.vertical, compact ? Spacing.sm : Spacing.md)
            .frame(maxWidth: compact ? nil : .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isEnabled ? Color.actionForeground : Color.actionForeground.opacity(0.5), lineWidth: Stroke.thin.width)
            )
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(configuration.isPressed ? Color.brand.opacity(0.08) : Color.clear)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
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
            .font(.uiLabel)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(isEnabled ? Color.destructiveFill : Color.destructiveFill.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1.0)
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
            .foregroundStyle(isEnabled ? Color.actionForeground : Color.actionForeground.opacity(0.5))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(configuration.isPressed ? Color.brand.opacity(0.08) : Color.clear)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1.0)
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
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.backgroundSecondary : Color.clear)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.9 : 1.0)
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
    /// Primary CTA button - filled brand color, full width
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    /// Inline primary button that hugs its content
    static var primaryCompact: PrimaryButtonStyle { PrimaryButtonStyle(compact: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// Secondary button - bordered outline, full width
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }

    /// Inline secondary button that hugs its content
    static var secondaryCompact: SecondaryButtonStyle { SecondaryButtonStyle(compact: true) }
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

// Shared functional controls, deliberately separate from Studio's export artwork.
private struct SemanticButtonsPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Passages").font(.screenTitle)
                Text("We read to know we are not alone.").font(.quoteBody)
                Text("Selected passage · Page 24").font(.uiPill)
                Button("Save 3 passages") {}.buttonStyle(.primary)
                Button("Inspect source page") {}.buttonStyle(.secondary)
                Button("Save passages") {}.buttonStyle(.primary).disabled(true)
                Button {} label: {
                    HStack {
                        ProgressView().tint(.white)
                        Text("Saving passages…")
                    }
                }
                .buttonStyle(.primary)
                .disabled(true)
                Label("Could not save. Your selection is still here.", systemImage: "exclamationmark.circle")
                    .font(.body).foregroundStyle(Color.error)
                Button("Retry saving") {}.buttonStyle(.primaryCompact)
                Label("3 passages saved", systemImage: "checkmark.circle")
                    .font(.body).foregroundStyle(Color.success)
                Button("Discard draft") {}.buttonStyle(.destructive)
                Button("View all passages") {}.buttonStyle(.ghost)
                Button {} label: { Image(systemName: "xmark") }
                    .buttonStyle(.iconSmall)
                    .accessibilityLabel("Close")
            }
            .padding(Spacing.lg)
        }
        .foregroundStyle(Color.textPrimary)
        .background(Color.backgroundPrimary)
    }
}

#Preview("Functional controls — light") {
    SemanticButtonsPreview().preferredColorScheme(.light)
}

#Preview("Functional controls — dark") {
    SemanticButtonsPreview().preferredColorScheme(.dark)
}

#Preview("Functional controls — accessibility XXXL") {
    // Reduce Motion is read-only in EnvironmentValues; use the preview device's setting.
    SemanticButtonsPreview()
        .dynamicTypeSize(.accessibility5)
}
