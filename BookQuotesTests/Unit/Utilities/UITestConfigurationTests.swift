import XCTest
import UIKit

@testable import BookQuotes

// MARK: - UITestConfigurationTests

final class UITestConfigurationTests: XCTestCase {

    func testDebugDescriptionWhenNotUITesting() {
        XCTAssertEqual(UITestConfiguration.debugDescription, "Not in UI testing mode")
    }
}

final class AccessibilityContrastTests: XCTestCase {

    func testTextColorsMeetWCAGContrastOnCardsInLightAndDarkModes() throws {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let card = try color(named: "BackgroundCard", traits: traits)
            let primary = try color(named: "TextPrimary", traits: traits)
            let secondary = try color(named: "TextSecondary", traits: traits)

            XCTAssertGreaterThanOrEqual(
                contrastRatio(primary, card),
                4.5,
                "TextPrimary must meet WCAG AA contrast in \(style) mode"
            )
            XCTAssertGreaterThanOrEqual(
                contrastRatio(secondary, card),
                4.5,
                "TextSecondary must meet WCAG AA contrast in \(style) mode"
            )
        }
    }

    private func color(named name: String, traits: UITraitCollection) throws -> UIColor {
        let color = try XCTUnwrap(UIColor(named: name), "Missing color asset: \(name)")
        return color.resolvedColor(with: traits)
    }

    private func contrastRatio(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let lighter = max(relativeLuminance(first), relativeLuminance(second))
        let darker = min(relativeLuminance(first), relativeLuminance(second))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))

        func linear(_ component: CGFloat) -> CGFloat {
            component <= 0.04045
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
