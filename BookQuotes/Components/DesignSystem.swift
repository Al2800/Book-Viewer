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

// MARK: - iOS 26 Liquid Glass Support

extension View {
    /// Apply glass card effect with iOS 26 Liquid Glass fallback
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg) -> some View {
        if #available(iOS 26, *) {
            self
                .background(.clear)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(Color.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }

    /// Apply glass button style with iOS 26 fallback
    @ViewBuilder
    func glassButton() -> some View {
        if #available(iOS 26, *) {
            self
                .buttonStyle(.glass)
        } else {
            self
                .buttonStyle(.bordered)
        }
    }
}

// MARK: - Animations

extension Animation {
    /// Smooth spring animation for general transitions
    static var smoothSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    /// Quick spring animation for responsive feedback
    static var quickSpring: Animation {
        .spring(response: 0.25, dampingFraction: 0.75)
    }
}

// MARK: - Transitions

extension AnyTransition {
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
}

// MARK: - Haptic Feedback

enum HapticManager {
    /// Trigger impact feedback with specified style
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Trigger notification feedback with specified type
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
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
}
