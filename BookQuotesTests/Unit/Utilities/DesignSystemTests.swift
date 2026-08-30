import XCTest
import SwiftUI
@testable import BookQuotes

final class DesignSystemTests: XCTestCase {

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
        _ = Font.sectionHeader
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
