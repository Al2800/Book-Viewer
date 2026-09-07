import XCTest
import SwiftUI
@testable import BookQuotes

final class DesignSystemTests: XCTestCase {

    @MainActor
    func testFunctionalTextAndUnfilledActionsMeetContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            for background in [Color.backgroundPrimary, .backgroundSecondary, .backgroundTertiary] {
                for foreground in [Color.textPrimary, .textSecondary, .actionForeground] {
                    XCTAssertGreaterThanOrEqual(contrast(foreground, background, style: style), 4.5,
                                                "Functional text must remain readable in \(style.rawValue)")
                }
            }
        }
    }

    @MainActor
    func testFilledActionLabelsMeetContrastInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            XCTAssertGreaterThanOrEqual(contrast(.white, .brand, style: style), 4.5)
            XCTAssertGreaterThanOrEqual(contrast(.white, .destructiveFill, style: style), 4.5)
        }
    }

    @MainActor
    private func contrast(_ first: Color, _ second: Color, style: UIUserInterfaceStyle) -> Double {
        func luminance(_ color: Color) -> Double {
            let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            XCTAssertEqual(alpha, 1)
            func linear(_ component: CGFloat) -> Double {
                let value = Double(component)
                return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let a = luminance(first), b = luminance(second)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    // MARK: - Typography Tests

    func testSerifTypographyTokensAreDefined() {
        _ = Font.serifTitleLarge
        _ = Font.serifHeadline
        _ = Font.quoteDisplay
        _ = Font.quoteLarge
        _ = Font.quoteBody
        _ = Font.marginScript
        _ = Font.marginScriptSmall
        _ = Font.attribution
        _ = Font.attributionSmall
        _ = Font.uiBadge
        _ = Font.uiPill
        _ = Font.uiLabel
        _ = Font.uiCaption
        _ = Font.screenTitle
        _ = Font.sectionHeader
        XCTAssertEqual(String(describing: Font.screenTitle), String(describing: Font.serifTitleLarge))
    }

    func testFunctionalTypographyUsesScalableSystemStyles() {
        XCTAssertEqual(Font.serifTitleLarge, Font.system(.largeTitle, design: .serif).weight(.semibold))
        XCTAssertEqual(Font.uiBadge, Font.system(.caption2).weight(.semibold))
        XCTAssertEqual(Font.uiPill, Font.system(.footnote).weight(.medium))
    }

    @MainActor
    func testCompactSemanticButtonsHaveMinimumTouchHeight() throws {
        let primary = ImageRenderer(content: Button("Save") {}.buttonStyle(.primaryCompact))
        let secondary = ImageRenderer(content: Button("Cancel") {}.buttonStyle(.secondaryCompact))
        let ghost = ImageRenderer(content: Button("View all") {}.buttonStyle(.ghost))
        let icon = ImageRenderer(content: Button {} label: {
            Image(systemName: "xmark").font(.caption2)
        }.buttonStyle(.iconSmall))

        for image in [primary.uiImage, secondary.uiImage, ghost.uiImage, icon.uiImage] {
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(image).size.height, 44)
        }
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(icon.uiImage).size.width, 44)
    }

    @MainActor
    func testAccessibleListStatusWrapsInsteadOfTruncating() throws {
        let regular = ImageRenderer(content:
            BookReadingStatusBadge(status: .currentlyReading, style: .list)
                .dynamicTypeSize(.large)
                .frame(width: 110)
        )
        let accessible = ImageRenderer(content:
            BookReadingStatusBadge(status: .currentlyReading, style: .list)
                .dynamicTypeSize(.accessibility5)
                .frame(width: 110)
        )
        let regularHeight = try XCTUnwrap(regular.uiImage).size.height
        let accessibleHeight = try XCTUnwrap(accessible.uiImage).size.height
        XCTAssertGreaterThan(accessibleHeight, regularHeight * 3,
                             "The status must grow vertically rather than remain a truncated single line")
    }

    // MARK: - Palette & Color Tests

    func testV2ThemePaletteColorsAreDefined() {
        _ = Color.darkLinen
        _ = Color.warmVellum
        _ = Color.editorialMonochrome
        _ = Color.gildedAccent
        _ = Color.goldFoil
    }

    // MARK: - Gradient Presets Tests

    func testV2GradientPresetsAreDefined() {
        _ = LinearGradient.foilAccent
        _ = LinearGradient.spineDepth
        _ = LinearGradient.cardHighlight
        _ = LinearGradient.brandAccent
        _ = LinearGradient.bottomFade
    }

    // MARK: - Shadow Tests

    func testShadowTokensProduceLightAndDarkModeColors() {
        let tiers: [Shadow] = [.xs, .sm, .md, .lg, .xl]

        for tier in tiers {
            XCTAssertGreaterThan(tier.radius, 0)
            XCTAssertGreaterThan(tier.y, 0)

            _ = tier.color(for: .light)
            _ = tier.color(for: .dark)
        }
    }

    // MARK: - Spacing & CornerRadius Tests

    func testSpacingTokensAreStrictlyIncreasing() {
        XCTAssertLessThan(Spacing.xxs, Spacing.xs)
        XCTAssertLessThan(Spacing.xs, Spacing.sm)
        XCTAssertLessThan(Spacing.sm, Spacing.md)
        XCTAssertLessThan(Spacing.md, Spacing.lg)
        XCTAssertLessThan(Spacing.lg, Spacing.xl)
        XCTAssertLessThan(Spacing.xl, Spacing.xxl)
        XCTAssertLessThan(Spacing.xxl, Spacing.xxxl)
    }

    func testCornerRadiusTokensAreStrictlyIncreasing() {
        XCTAssertLessThan(CornerRadius.sm, CornerRadius.md)
        XCTAssertLessThan(CornerRadius.md, CornerRadius.lg)
        XCTAssertLessThan(CornerRadius.lg, CornerRadius.xl)
    }
}
