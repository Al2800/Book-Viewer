import SwiftUI

// MARK: - Color Tokens

extension Color {
    // MARK: - Brand Colors
    /// Deep warm blue #2C3E50
    static let brand = Color("Brand")
    /// Lighter brand variant #34495E
    static let brandLight = Color("BrandLight")
    /// Warm gold accent #D4A574
    static let accent = Color("Accent")

    // MARK: - Background
    /// Warm white #FAFAF8
    static let backgroundPrimary = Color("BackgroundPrimary")
    /// Subtle cream #F5F5F0
    static let backgroundSecondary = Color("BackgroundSecondary")
    /// Light gray for tertiary backgrounds #EAEAE5
    static let backgroundTertiary = Color("BackgroundTertiary")
    /// Paper white #FFFFFF
    static let backgroundCard = Color("BackgroundCard")

    // MARK: - Text
    /// Rich black #1A1A1A
    static let textPrimary = Color("TextPrimary")
    /// Soft gray #6B6B6B
    static let textSecondary = Color("TextSecondary")
    /// Light gray #9A9A9A
    static let textTertiary = Color("TextTertiary")

    // MARK: - Semantic
    /// Muted green #4A7C59
    static let success = Color("Success")
    /// Muted amber #C9A227
    static let warning = Color("Warning")
    /// Muted red #A35D5D
    static let error = Color("Error")

    // MARK: - Quote Card
    /// Warm paper #FFFEF9
    static let quoteBackground = Color("QuoteBackground")
    /// Subtle line #E8E8E0
    static let quoteBorder = Color("QuoteBorder")

    // MARK: - Confidence Indicators
    static let confidenceHigh = Color.green
    static let confidenceMedium = Color.yellow
    static let confidenceLow = Color.red
}

// MARK: - Dark Mode Support

extension ShapeStyle where Self == Color {
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }

    static var adaptiveBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
                : UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1)
        })
    }
}

// MARK: - Typography

extension Font {
    // MARK: - Display (for large quotes)
    /// Title-sized serif font for featured quotes
    static let quoteDisplay = Font.system(.title2, design: .serif)
    /// Large serif font for standard quotes
    static let quoteLarge = Font.system(.title3, design: .serif)
    /// Body-sized serif font for quote text
    static let quoteBody = Font.system(.body, design: .serif)

    // MARK: - Attribution
    /// Serif italic for attributions
    static let attribution = Font.system(.subheadline, design: .serif).italic()
    /// Small serif italic for secondary attributions
    static let attributionSmall = Font.system(.caption, design: .serif).italic()

    // MARK: - UI Text
    /// Semibold serif for book titles
    static let bookTitle = Font.system(.headline, design: .serif).weight(.semibold)
    /// Standard serif for author names
    static let authorName = Font.system(.subheadline, design: .serif)
    /// Semibold footnote for section headers
    static let sectionHeader = Font.system(.footnote).weight(.semibold)
    /// Standard body text
    static let bodyText = Font.system(.body)
    /// Caption text
    static let caption = Font.system(.caption)
}

// MARK: - Quote Text Styling

extension View {
    /// Apply standard quote text styling with proper line spacing
    func quoteTextStyle() -> some View {
        self
            .font(.quoteBody)
            .lineSpacing(6)
            .foregroundStyle(Color.textPrimary)
    }
}

// MARK: - Spacing

enum Spacing {
    /// 2pt - Extra extra small
    static let xxs: CGFloat = 2
    /// 4pt - Extra small
    static let xs: CGFloat = 4
    /// 8pt - Small
    static let sm: CGFloat = 8
    /// 12pt - Medium
    static let md: CGFloat = 12
    /// 16pt - Large
    static let lg: CGFloat = 16
    /// 24pt - Extra large
    static let xl: CGFloat = 24
    /// 32pt - Extra extra large
    static let xxl: CGFloat = 32
    /// 48pt - Extra extra extra large
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    /// 6pt - Small corners
    static let sm: CGFloat = 6
    /// 10pt - Medium corners
    static let md: CGFloat = 10
    /// 16pt - Large corners
    static let lg: CGFloat = 16
    /// 24pt - Extra large corners
    static let xl: CGFloat = 24
}

// MARK: - Shadow Tokens

/// Tiered shadow system for consistent elevation across components.
/// Use semantic levels (xs → xl) instead of hardcoded shadow values.
enum Shadow {
    /// Subtle lift - cards at rest, minimal elevation
    case xs
    /// Light elevation - hovered cards, slight depth
    case sm
    /// Medium depth - modals, popovers, focused elements
    case md
    /// High elevation - dropdowns, tooltips, important overlays
    case lg
    /// Floating elements - drag previews, maximum elevation
    case xl

    /// Shadow color with opacity adjusted per tier
    var color: Color {
        switch self {
        case .xs: return Color.black.opacity(0.04)
        case .sm: return Color.black.opacity(0.08)
        case .md: return Color.black.opacity(0.12)
        case .lg: return Color.black.opacity(0.16)
        case .xl: return Color.black.opacity(0.20)
        }
    }

    /// Shadow blur radius
    var radius: CGFloat {
        switch self {
        case .xs: return 2
        case .sm: return 4
        case .md: return 8
        case .lg: return 12
        case .xl: return 20
        }
    }

    /// Vertical offset (shadows cast downward)
    var y: CGFloat {
        switch self {
        case .xs: return 1
        case .sm: return 2
        case .md: return 4
        case .lg: return 8
        case .xl: return 12
        }
    }

    /// Dark mode adjusted color (reduced opacity for dark backgrounds)
    func color(for colorScheme: ColorScheme) -> Color {
        let darkModeMultiplier: Double = 0.7
        switch self {
        case .xs: return Color.black.opacity(colorScheme == .dark ? 0.04 * darkModeMultiplier : 0.04)
        case .sm: return Color.black.opacity(colorScheme == .dark ? 0.08 * darkModeMultiplier : 0.08)
        case .md: return Color.black.opacity(colorScheme == .dark ? 0.12 * darkModeMultiplier : 0.12)
        case .lg: return Color.black.opacity(colorScheme == .dark ? 0.16 * darkModeMultiplier : 0.16)
        case .xl: return Color.black.opacity(colorScheme == .dark ? 0.20 * darkModeMultiplier : 0.20)
        }
    }
}

extension View {
    /// Apply semantic elevation shadow to a view.
    /// - Parameter shadow: The shadow tier to apply (xs, sm, md, lg, xl)
    /// - Returns: View with shadow applied
    ///
    /// Usage:
    /// ```swift
    /// // Cards at rest
    /// CardView().elevation(.xs)
    ///
    /// // Hovered/focused cards
    /// CardView().elevation(.sm)
    ///
    /// // Modals and popovers
    /// ModalView().elevation(.md)
    ///
    /// // Dropdowns and tooltips
    /// DropdownView().elevation(.lg)
    ///
    /// // Floating drag previews
    /// DragPreview().elevation(.xl)
    /// ```
    func elevation(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
    }

    /// Apply semantic elevation with dark mode awareness
    func elevation(_ shadow: Shadow, colorScheme: ColorScheme) -> some View {
        self.shadow(color: shadow.color(for: colorScheme), radius: shadow.radius, y: shadow.y)
    }
}

// MARK: - Gradient Presets

extension LinearGradient {
    /// Fade to background at bottom - for scroll indicators and infinite scroll feel
    /// Use at bottom of scrollable content lists
    static let bottomFade = LinearGradient(
        colors: [.clear, Color.backgroundPrimary],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dark overlay for text readability on images
    /// Apply over book covers or photos where text will appear
    static let imageTextOverlay = LinearGradient(
        colors: [.clear, Color.black.opacity(0.6)],
        startPoint: .center,
        endPoint: .bottom
    )

    /// Brand gradient for premium elements and CTAs
    /// Use for upgrade buttons, premium badges, special features
    static let brandAccent = LinearGradient(
        colors: [Color.brand, Color.accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle highlight for cards - creates glass-like effect
    /// Apply as overlay on cards for subtle depth
    static let cardHighlight = LinearGradient(
        colors: [Color.white.opacity(0.08), .clear],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Camera controls overlay - dark gradient for control visibility
    /// Use in camera views for bottom control areas
    static let cameraControls = LinearGradient(
        colors: [.clear, Color.black.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Success gradient for celebration moments
    /// Use for achievement banners, success states
    static let successGlow = LinearGradient(
        colors: [Color.success.opacity(0.3), Color.success.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Surface gradient for subtle card backgrounds
    /// Use for cards that need differentiation without harsh borders
    static let surfaceGradient = LinearGradient(
        colors: [Color.backgroundCard, Color.backgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Stroke Tokens

/// Semantic stroke/border width tokens for consistent borders across components.
/// Use these instead of hardcoded lineWidth values.
enum Stroke {
    /// 0.5pt - Subtle separators, hairline borders
    case hairline
    /// 1pt - Standard borders, card outlines
    case thin
    /// 2pt - Focus rings, emphasis borders
    case medium
    /// 3pt - Strong emphasis, active states
    case thick
    /// 4pt - Dramatic borders, special emphasis
    case heavy

    /// The stroke width in points
    var width: CGFloat {
        switch self {
        case .hairline: return 0.5
        case .thin: return 1
        case .medium: return 2
        case .thick: return 3
        case .heavy: return 4
        }
    }
}

extension View {
    /// Apply a semantic stroke border with specified corner radius
    /// - Parameters:
    ///   - stroke: The stroke weight (hairline, thin, medium, thick, heavy)
    ///   - color: Border color (defaults to quoteBorder)
    ///   - cornerRadius: Corner radius for the border shape
    func strokeBorder(_ stroke: Stroke, color: Color = .quoteBorder, cornerRadius: CGFloat = CornerRadius.md) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: stroke.width)
        )
    }
}

// MARK: - Overlay Opacity Tokens

/// Semantic overlay opacity scale for consistent dimming effects.
/// Use these for modal scrims, loading overlays, and background dimming.
enum Overlay {
    /// 0.15 - Subtle hint of darkness, content still prominent
    case subtle
    /// 0.30 - Standard modal scrim (most common)
    case light
    /// 0.50 - Moderate dimming for photo viewers
    case medium
    /// 0.70 - Strong focus on overlay content
    case heavy
    /// 0.85 - Near-solid, maximum focus on overlay
    case opaque

    /// The opacity value (0.0 - 1.0)
    var opacity: Double {
        switch self {
        case .subtle: return 0.15
        case .light: return 0.30
        case .medium: return 0.50
        case .heavy: return 0.70
        case .opaque: return 0.85
        }
    }
}

extension Color {
    /// Create a scrim (dimming overlay) color with semantic opacity
    /// - Parameter overlay: The overlay intensity level
    /// - Returns: Black color with appropriate opacity
    static func scrim(_ overlay: Overlay) -> Color {
        Color.black.opacity(overlay.opacity)
    }
}

// MARK: - Accessibility Manager

/// Centralized accessibility state manager for motion and transparency preferences.
/// Use this to check user preferences before applying animations.
@Observable
final class AccessibilityManager {
    /// Shared singleton instance
    static let shared = AccessibilityManager()

    /// Whether the user prefers reduced motion (Settings > Accessibility > Motion > Reduce Motion)
    var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Whether the user prefers reduced transparency
    var prefersReducedTransparency: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    private init() {
        // Listen for changes to update views reactively
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Trigger re-evaluation of prefersReducedMotion
            // @Observable will handle view updates
            _ = self?.prefersReducedMotion
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _ = self?.prefersReducedTransparency
        }
    }
}

// MARK: - iOS 26 Liquid Glass Support

extension View {
    /// Apply glass card effect with iOS 26 Liquid Glass.
    /// Falls back to ultraThinMaterial on earlier iOS versions.
    ///
    /// Usage:
    /// ```swift
    /// VStack { ... }
    ///     .padding()
    ///     .glassCard()
    /// ```
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg, elevated: Bool = true) -> some View {
        if #available(iOS 26, *) {
            // iOS 26: Use native Liquid Glass effect
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial)
                        .glassEffect()
                }
                // Without an explicit clip, some iOS 26 glass backgrounds can render as a rectangular
                // layer behind the rounded overlay, which looks like two styles stacked.
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            // Pre-iOS 26: Material-based fallback with similar visual feel
            if elevated {
                self
                    .background {
                        // Avoid rectangular material backgrounds showing behind rounded overlays.
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .elevation(.sm)
            } else {
                // For chrome layered on top of a live camera preview, even a small shadow reads as a dark slab.
                // Use the same shaped material but skip elevation.
                self
                    .background {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
    }

    /// Apply glass button style with iOS 26 Liquid Glass.
    /// Falls back to borderedProminent with accent tint on earlier iOS.
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26, *) {
            // iOS 26: Use native glass button style if available
            self.buttonStyle(.glass)
        } else {
            // Pre-iOS 26: Bordered prominent with accent tint
            self
                .buttonStyle(.borderedProminent)
                .tint(Color.accent.opacity(0.9))
        }
    }

    /// Apply glass toolbar background with iOS 26 Liquid Glass.
    /// Falls back to ultraThinMaterial on earlier iOS versions.
    @ViewBuilder
    func glassToolbar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    /// Apply glass tab bar background with iOS 26 Liquid Glass.
    @ViewBuilder
    func glassTabBar() -> some View {
        self.toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }

    /// Apply glass effect to floating elements (FABs, toasts).
    /// More prominent than glassCard with additional shadow.
    @ViewBuilder
    func glassFloating(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        if #available(iOS 26, *) {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thickMaterial)
                        .glassEffect()
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .elevation(.lg)
        } else {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thickMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .elevation(.lg)
        }
    }

    /// Apply warm paper card styling with a subtle glassy highlight.
    /// Designed for form sections and content blocks.
    func paperCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.backgroundCard)
                    .overlay {
                        LinearGradient.cardHighlight
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.quoteBorder.opacity(0.7), lineWidth: Stroke.hairline.width)
                    }
            }
            .elevation(.xs)
    }

    /// Apply consistent field styling for inputs.
    func fieldChrome(minHeight: CGFloat? = nil) -> some View {
        self
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
            )
    }
}

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

// MARK: - Haptic Feedback

enum HapticManager {
    /// Key for the haptic feedback enabled preference
    private static let hapticFeedbackEnabledKey = "hapticFeedbackEnabled"

    /// Whether haptic feedback is enabled (defaults to true)
    static var isEnabled: Bool {
        // Default to true if not set (maintains existing behavior for current users)
        if UserDefaults.standard.object(forKey: hapticFeedbackEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: hapticFeedbackEnabledKey)
    }

    /// Trigger impact feedback with specified style
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger notification feedback with specified type
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - Common Haptics

    /// Success haptic for capture completion
    static func captureSuccess() {
        notification(.success)
    }

    /// Light impact for subtle interactions
    static func light() {
        impact(.light)
    }

    /// Medium impact for emphasis
    static func medium() {
        impact(.medium)
    }

    /// Success notification feedback
    static func success() {
        notification(.success)
    }

    /// Warning notification feedback
    static func warning() {
        notification(.warning)
    }

    /// Light impact for quote added
    static func quoteAdded() {
        impact(.light)
    }

    /// Medium impact for favorite toggle
    static func favoriteToggled() {
        impact(.medium)
    }

    /// Error haptic for failures
    static func error() {
        notification(.error)
    }

    /// Selection changed haptic for pickers, toggles
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

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

// MARK: - Conditional View Modifier

extension View {
    /// Conditionally apply a view modifier.
    /// - Parameters:
    ///   - condition: Boolean condition to check
    ///   - transform: Transform to apply when condition is true
    /// - Returns: Modified view when condition is true, original view otherwise
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally apply one of two view modifiers.
    /// - Parameters:
    ///   - condition: Boolean condition to check
    ///   - ifTransform: Transform to apply when condition is true
    ///   - elseTransform: Transform to apply when condition is false
    /// - Returns: Modified view based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Context Menu Animations

/// View modifier that adds a polished context menu with haptic feedback and lift animation.
/// Provides a custom preview that elevates on long press before the menu appears.
struct PolishedContextMenuModifier<MenuItems: View, Preview: View>: ViewModifier {
    let menuItems: () -> MenuItems
    let preview: () -> Preview
    let onPresent: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPresenting = false

    init(
        @ViewBuilder menuItems: @escaping () -> MenuItems,
        @ViewBuilder preview: @escaping () -> Preview,
        onPresent: (() -> Void)? = nil
    ) {
        self.menuItems = menuItems
        self.preview = preview
        self.onPresent = onPresent
    }

    func body(content: Content) -> some View {
        content
            .contextMenu(menuItems: menuItems, preview: preview)
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                if isPressing && !isPresenting {
                    // Haptic as menu begins to appear
                    HapticManager.medium()
                    onPresent?()
                    isPresenting = true
                }
                if !isPressing {
                    isPresenting = false
                }
            }, perform: {})
    }
}

/// Simplified context menu modifier when preview matches content.
struct SimpleContextMenuModifier<MenuItems: View>: ViewModifier {
    let menuItems: () -> MenuItems

    func body(content: Content) -> some View {
        content
            .contextMenu(menuItems: menuItems)
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                if isPressing {
                    HapticManager.medium()
                }
            }, perform: {})
    }
}

extension View {
    /// Add a polished context menu with custom preview and haptic feedback.
    /// - Parameters:
    ///   - menuItems: The menu content shown on long press
    ///   - preview: Custom preview view shown during context menu presentation
    ///   - onPresent: Optional callback when context menu begins presenting
    func polishedContextMenu<MenuItems: View, Preview: View>(
        @ViewBuilder menuItems: @escaping () -> MenuItems,
        @ViewBuilder preview: @escaping () -> Preview,
        onPresent: (() -> Void)? = nil
    ) -> some View {
        modifier(PolishedContextMenuModifier(
            menuItems: menuItems,
            preview: preview,
            onPresent: onPresent
        ))
    }

    /// Add a polished context menu with haptic feedback (uses content as preview).
    /// - Parameter menuItems: The menu content shown on long press
    func polishedContextMenu<MenuItems: View>(
        @ViewBuilder menuItems: @escaping () -> MenuItems
    ) -> some View {
        modifier(SimpleContextMenuModifier(menuItems: menuItems))
    }
}

// MARK: - Context Menu Preview Wrappers

/// Preview wrapper that adds elevation and polish for context menu previews.
struct ContextMenuPreview<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(cornerRadius: CGFloat = CornerRadius.md, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .elevation(.lg, colorScheme: colorScheme)
    }
}

/// Quote context menu preview with styled container
struct QuoteContextMenuPreview: View {
    let quote: Quote
    let showBookInfo: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(quote: Quote, showBookInfo: Bool = false) {
        self.quote = quote
        self.showBookInfo = showBookInfo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(quote.text)
                .font(.quoteBody)
                .lineLimit(6)
                .foregroundStyle(Color.textPrimary)

            if showBookInfo, let book = quote.book {
                Divider()
                HStack {
                    Text(book.title)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("by \(book.author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if quote.isFavorite {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Favorite")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: 300)
        .background(Color.quoteBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.quoteBorder, lineWidth: 1)
        }
        .elevation(.lg, colorScheme: colorScheme)
    }
}

/// Book context menu preview with cover and info
struct BookContextMenuPreview: View {
    let book: Book

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Cover image
            if let coverData = book.coverThumbnailData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            } else {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.backgroundSecondary)
                    .frame(width: 60, height: 90)
                    .overlay {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if book.hasQuotes {
                    Text("\(book.quoteCount) quotes")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Text(book.status.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accent.opacity(0.15))
                    .foregroundStyle(Color.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.md)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .elevation(.lg, colorScheme: colorScheme)
    }
}

// MARK: - Swipe Action Helpers

/// Common swipe action button configurations with haptic feedback.
/// Use these in `.swipeActions` for consistent UX.
enum SwipeActionStyle {
    /// Creates a delete swipe action button with haptic feedback
    static func deleteButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            HapticManager.warning()
            action()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    /// Creates a remove swipe action button with haptic feedback
    static func removeButton(action: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            HapticManager.warning()
            action()
        } label: {
            Label("Remove", systemImage: "minus.circle")
        }
    }

    /// Creates a favorite swipe action button with haptic feedback
    static func favoriteButton(isFavorite: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.favoriteToggled()
            action()
        } label: {
            Label(
                isFavorite ? "Unfavorite" : "Favorite",
                systemImage: isFavorite ? "heart.slash.fill" : "heart.fill"
            )
        }
        .tint(isFavorite ? .secondary : .pink)
    }

    /// Creates an edit swipe action button with haptic feedback
    static func editButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
    }

    /// Creates a share swipe action button with haptic feedback
    static func shareButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .tint(.indigo)
    }

    /// Creates an archive swipe action button with haptic feedback
    static func archiveButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(.orange)
    }

    /// Creates a copy swipe action button with haptic feedback
    static func copyButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        .tint(.teal)
    }

    /// Creates a flag swipe action button with haptic feedback
    static func flagButton(isFlagged: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Label(
                isFlagged ? "Unflag" : "Flag",
                systemImage: isFlagged ? "flag.slash.fill" : "flag.fill"
            )
        }
        .tint(isFlagged ? .secondary : .orange)
    }
}

// MARK: - Keyboard Toolbar

extension View {
    /// Adds a "Done" button toolbar for numeric keyboards to dismiss the keyboard.
    /// Use this on TextFields with `.numberPad` or `.decimalPad` keyboard types.
    ///
    /// Example:
    /// ```swift
    /// TextField("Page", text: $pageNumber)
    ///     .keyboardType(.numberPad)
    ///     .numericKeyboardDoneButton()
    /// ```
    func numericKeyboardDoneButton() -> some View {
        modifier(NumericKeyboardToolbarModifier())
    }
}

/// View modifier that adds a Done button toolbar for numeric keyboards.
private struct NumericKeyboardToolbarModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        HapticManager.light()
                        isFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
    }
}
