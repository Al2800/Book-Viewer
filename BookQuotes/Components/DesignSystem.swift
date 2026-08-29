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
    static let confidenceHigh = Color.success
    static let confidenceMedium = Color.warning
    static let confidenceLow = Color.error

    // MARK: - V2 Theme Palette
    /// Dark Linen luxury card background #141414
    static let darkLinen = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
            : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    })

    /// Warm Vellum tactile paper background #F7F4EC
    static let warmVellum = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.17, blue: 0.15, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1.0)
    })

    /// Editorial Monochrome soft paper tone #ECECE8
    static let editorialMonochrome = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1.0)
            : UIColor(red: 0.92, green: 0.92, blue: 0.91, alpha: 1.0)
    })

    /// Gilded gold accent #D4AF37
    static let gildedAccent = Color(red: 0.83, green: 0.69, blue: 0.22)

    /// Deep gold foil #C5A059
    static let goldFoil = Color(red: 0.77, green: 0.63, blue: 0.35)
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
    // MARK: - Display & Hero Headlines
    /// Extra large display serif for hero quote cards and prominent headers
    static let serifTitleLarge = Font.system(size: 34, weight: .semibold, design: .serif)
    /// Large headline serif font for section headers and book cards
    static let serifHeadline = Font.system(.headline, design: .serif).weight(.semibold)
    /// Title-sized serif font for featured quotes
    static let quoteDisplay = Font.system(.title2, design: .serif)
    /// Large serif font for standard quotes
    static let quoteLarge = Font.system(.title3, design: .serif)
    /// Body-sized serif font for quote text
    static let quoteBody = Font.system(.body, design: .serif)

    // MARK: - Margin Script (organic handwriting for margin notes)
    /// Organic handwritten script font for margin notes
    static let marginScript = Font.system(.body, design: .serif).italic()
    /// Small margin script font
    static let marginScriptSmall = Font.system(.caption, design: .serif).italic()

    // MARK: - Attribution
    /// Serif italic for attributions
    static let attribution = Font.system(.subheadline, design: .serif).italic()
    /// Small serif italic for secondary attributions
    static let attributionSmall = Font.system(.caption, design: .serif).italic()

    // MARK: - UI Text
    /// Large serif title for book detail headers
    static let bookTitleLarge = Font.system(.title2, design: .serif).weight(.semibold)
    /// Semibold serif for book titles
    static let bookTitle = Font.system(.headline, design: .serif).weight(.semibold)
    /// Compact serif title for grid cards and dense rows
    static let bookTitleSmall = Font.system(.subheadline, design: .serif).weight(.semibold)
    /// Standard serif for author names
    static let authorName = Font.system(.subheadline, design: .serif)
    /// Small serif for author names in compact contexts
    static let authorNameSmall = Font.system(.caption, design: .serif)
    /// Serif footnote for compact quote text
    static let quoteCompact = Font.system(.footnote, design: .serif)
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

    /// Chapter-style section header: small and uppercased.
    /// Use for section titles inside paper cards and detail screens.
    func sectionHeaderStyle() -> some View {
        self
            .font(.sectionHeader)
            .textCase(.uppercase)
            .foregroundStyle(Color.textSecondary)
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
    /// 3pt - Extra small corners
    static let xs: CGFloat = 3
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

    /// Gold foil accent gradient for ribbons and emblems
    static let foilAccent = LinearGradient(
        colors: [
            Color(red: 0.90, green: 0.78, blue: 0.45),
            Color(red: 0.77, green: 0.63, blue: 0.35),
            Color(red: 0.85, green: 0.72, blue: 0.40)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Book spine depth gradient creating 3D physical book feel
    static let spineDepth = LinearGradient(
        colors: [
            Color.black.opacity(0.24),
            Color.black.opacity(0.08),
            Color.white.opacity(0.06),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
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
