import Foundation
import UIKit

extension TestFixtures {
    // MARK: - OCR Cover Fixtures

    /// Synthetic cover images for Vision OCR golden tests.
    ///
    /// Why synthetic:
    /// - Avoids licensing/copyright issues with real book covers.
    /// - Deterministic rendering (layout, fonts, colors) for stable OCR expectations.
    ///
    /// Notes:
    /// - These are not meant to look photorealistic, only to exercise OCR on realistic-ish cover layouts.
    enum OCRCoverFixtures {
        struct Cover {
            let id: String
            let expectedTitle: String
            let expectedAuthor: String
            let image: UIImage

            var pngData: Data {
                image.pngData() ?? Data()
            }
        }

        static let boldCentered: Cover = makeCover(
            id: "bold_centered",
            title: "Atomic Habits",
            author: "James Clear",
            subtitle: "Tiny Changes, Remarkable Results",
            style: .boldCentered
        )

        static let serifTopHeavy: Cover = makeCover(
            id: "serif_top_heavy",
            title: "Deep Work",
            author: "Cal Newport",
            subtitle: "Rules for Focused Success",
            style: .serifTopHeavy
        )

        static let mixedCaseBadge: Cover = makeCover(
            id: "mixed_case_badge",
            title: "Thinking, Fast and Slow",
            author: "Daniel Kahneman",
            subtitle: nil,
            style: .mixedCaseBadge
        )

        static let slightlyRotated: Cover = makeCover(
            id: "slightly_rotated",
            title: "The Letters of Private Wheeler",
            author: "B.H. Liddell Hart",
            subtitle: "A Study in Strategy",
            style: .slightlyRotated
        )

        static var all: [Cover] {
            [boldCentered, serifTopHeavy, mixedCaseBadge, slightlyRotated]
        }

        // MARK: - Internals

        private enum Style {
            case boldCentered
            case serifTopHeavy
            case mixedCaseBadge
            case slightlyRotated
        }

        private static func makeCover(
            id: String,
            title: String,
            author: String,
            subtitle: String?,
            style: Style
        ) -> Cover {
            let size = CGSize(width: 360, height: 540)
            let renderer = UIGraphicsImageRenderer(size: size)

            let image = renderer.image { ctx in
                let cg = ctx.cgContext

                switch style {
                case .boldCentered:
                    drawGradientBackground(cg, size: size, top: UIColor.systemIndigo, bottom: UIColor.systemTeal)
                case .serifTopHeavy:
                    drawGradientBackground(cg, size: size, top: UIColor.systemBrown, bottom: UIColor.systemOrange)
                case .mixedCaseBadge:
                    drawGradientBackground(cg, size: size, top: UIColor.systemGray, bottom: UIColor.systemBlue)
                case .slightlyRotated:
                    drawGradientBackground(cg, size: size, top: UIColor.systemGreen, bottom: UIColor.systemIndigo)
                }

                UIColor.white.withAlphaComponent(0.12).setFill()
                ctx.fill(CGRect(x: 28, y: 28, width: 90, height: 90))
                ctx.fill(CGRect(x: size.width - 140, y: size.height - 170, width: 112, height: 112))

                let card = CGRect(x: 24, y: 110, width: size.width - 48, height: size.height - 220)
                let cardPath = UIBezierPath(roundedRect: card, cornerRadius: 22)
                UIColor.white.withAlphaComponent(0.92).setFill()
                cardPath.fill()

                if style == .slightlyRotated {
                    cg.saveGState()
                    let center = CGPoint(x: card.midX, y: card.midY)
                    cg.translateBy(x: center.x, y: center.y)
                    cg.rotate(by: -0.03)
                    cg.translateBy(x: -center.x, y: -center.y)
                }

                let titleFont: UIFont
                let authorFont: UIFont
                let subtitleFont: UIFont

                switch style {
                case .boldCentered:
                    titleFont = preferredFont(named: "AvenirNext-Heavy", fallback: .systemFont(ofSize: 36, weight: .heavy))
                    authorFont = preferredFont(named: "AvenirNext-DemiBold", fallback: .systemFont(ofSize: 18, weight: .semibold))
                    subtitleFont = preferredFont(named: "AvenirNext-Regular", fallback: .systemFont(ofSize: 16, weight: .regular))
                case .serifTopHeavy:
                    titleFont = preferredFont(named: "Georgia-Bold", fallback: .systemFont(ofSize: 34, weight: .bold))
                    authorFont = preferredFont(named: "Georgia", fallback: .systemFont(ofSize: 18, weight: .medium))
                    subtitleFont = preferredFont(named: "Georgia-Italic", fallback: .italicSystemFont(ofSize: 16))
                case .mixedCaseBadge:
                    titleFont = preferredFont(named: "HelveticaNeue-CondensedBold", fallback: .systemFont(ofSize: 34, weight: .bold))
                    authorFont = preferredFont(named: "HelveticaNeue-Medium", fallback: .systemFont(ofSize: 18, weight: .medium))
                    subtitleFont = preferredFont(named: "HelveticaNeue", fallback: .systemFont(ofSize: 16, weight: .regular))
                case .slightlyRotated:
                    titleFont = preferredFont(named: "TimesNewRomanPS-BoldMT", fallback: .systemFont(ofSize: 30, weight: .bold))
                    authorFont = preferredFont(named: "TimesNewRomanPSMT", fallback: .systemFont(ofSize: 18, weight: .regular))
                    subtitleFont = preferredFont(named: "TimesNewRomanPS-ItalicMT", fallback: .italicSystemFont(ofSize: 16))
                }

                let textColor = UIColor.black.withAlphaComponent(0.92)

                if style == .mixedCaseBadge {
                    let badge = CGRect(x: card.minX + 18, y: card.minY + 18, width: 110, height: 32)
                    let badgePath = UIBezierPath(roundedRect: badge, cornerRadius: 16)
                    UIColor.black.withAlphaComponent(0.08).setFill()
                    badgePath.fill()
                    drawText(
                        "Bestseller",
                        in: badge.insetBy(dx: 10, dy: 6),
                        font: preferredFont(named: "HelveticaNeue-Medium", fallback: .systemFont(ofSize: 14, weight: .medium)),
                        color: textColor,
                        alignment: .center
                    )
                }

                let titleRect = CGRect(x: card.minX + 22, y: card.minY + 70, width: card.width - 44, height: 170)
                let authorRect = CGRect(x: card.minX + 22, y: card.maxY - 88, width: card.width - 44, height: 34)
                let subtitleRect = CGRect(x: card.minX + 22, y: authorRect.minY - 56, width: card.width - 44, height: 46)

                drawText(
                    title,
                    in: titleRect,
                    font: titleFont,
                    color: textColor,
                    alignment: (style == .boldCentered) ? .center : .left
                )

                if let subtitle, subtitle.isEmpty == false {
                    drawText(
                        subtitle,
                        in: subtitleRect,
                        font: subtitleFont,
                        color: textColor.withAlphaComponent(0.75),
                        alignment: (style == .boldCentered) ? .center : .left
                    )
                }

                drawText(
                    author,
                    in: authorRect,
                    font: authorFont,
                    color: textColor.withAlphaComponent(0.85),
                    alignment: (style == .boldCentered) ? .center : .left
                )

                if style == .slightlyRotated {
                    cg.restoreGState()
                }
            }

            return Cover(id: id, expectedTitle: title, expectedAuthor: author, image: image)
        }

        private static func preferredFont(named: String, fallback: UIFont) -> UIFont {
            UIFont(name: named, size: fallback.pointSize) ?? fallback
        }

        private static func drawGradientBackground(_ cg: CGContext, size: CGSize, top: UIColor, bottom: UIColor) {
            let colors = [top.cgColor, bottom.cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )
            if let gradient {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: size.height),
                    options: []
                )
            } else {
                top.setFill()
                cg.fill(CGRect(origin: .zero, size: size))
            }
        }

        private static func drawText(
            _ text: String,
            in rect: CGRect,
            font: UIFont,
            color: UIColor,
            alignment: NSTextAlignment
        ) {
            let style = NSMutableParagraphStyle()
            style.alignment = alignment
            style.lineBreakMode = .byWordWrapping
            style.lineSpacing = 4

            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style,
                .kern: 0.3
            ]

            (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
        }
    }
}
