import UIKit

// MARK: - Mock Camera Images

/// Provides test images for UI testing without requiring a real camera.
///
/// This utility generates programmatic images that simulate book pages with
/// marked passages. For production testing, replace these with actual
/// photographed test images in the app bundle.
///
/// Usage is controlled by `UITestConfiguration`:
/// - `--mock-camera`: Enables mock camera mode
/// - `--mock-multiple-quotes`: Returns images with multiple marked passages
/// - `--mock-low-confidence`: Returns images that simulate poor capture quality
enum MockCameraImages {

    // MARK: - Test Image Generation

    /// Get a test image based on the current test configuration.
    /// - Parameters:
    ///   - multipleQuotes: Whether to return an image with multiple passages
    ///   - lowConfidence: Whether to simulate a low-quality capture
    ///   - index: Index for cycling through multiple test images
    /// - Returns: A test image for UI testing
    static func getTestImage(
        multipleQuotes: Bool,
        lowConfidence: Bool,
        index: Int
    ) -> UIImage {
        // First, try to load from bundle (preferred for realistic testing)
        if let bundledImage = loadBundledTestImage(
            multipleQuotes: multipleQuotes,
            lowConfidence: lowConfidence,
            index: index
        ) {
            return bundledImage
        }

        // Fall back to programmatically generated images
        return generateTestImage(
            multipleQuotes: multipleQuotes,
            lowConfidence: lowConfidence,
            index: index
        )
    }

    // MARK: - Bundle Loading

    /// Attempt to load a test image from the app bundle.
    private static func loadBundledTestImage(
        multipleQuotes: Bool,
        lowConfidence: Bool,
        index: Int
    ) -> UIImage? {
        // Build image name based on scenario
        var imageName = "test-page"

        if multipleQuotes {
            imageName += "-multi"
        } else {
            imageName += "-single"
        }

        if lowConfidence {
            imageName += "-blurry"
        }

        // Add index for variety
        let numberedName = "\(imageName)-\(index % 3)"

        // Try numbered first, then base name
        if let image = UIImage(named: numberedName) {
            return image
        }

        if let image = UIImage(named: imageName) {
            return image
        }

        return nil
    }

    // MARK: - Programmatic Generation

    /// Generate a synthetic test image when no bundle image is available.
    private static func generateTestImage(
        multipleQuotes: Bool,
        lowConfidence: Bool,
        index: Int
    ) -> UIImage {
        let size = CGSize(width: 1200, height: 1600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // Background - cream/off-white like a book page
            let backgroundColor: UIColor = lowConfidence ? .systemGray5 : UIColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)
            backgroundColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Add page margins
            let margins: CGFloat = 80
            let textArea = CGRect(
                x: margins,
                y: margins,
                width: size.width - margins * 2,
                height: size.height - margins * 2
            )

            // Generate mock text lines
            let lineHeight: CGFloat = 28
            let lineSpacing: CGFloat = 12
            var currentY = textArea.minY

            let textColor: UIColor = lowConfidence ? .systemGray2 : .black
            let highlightColor = UIColor.yellow.withAlphaComponent(0.5)

            // Simulated paragraph structure
            let paragraphLengths = [5, 8, 6, 7, 5, 9, 6, 8, 7, 6, 8, 5, 7, 9, 6]

            var lineIndex = 0

            // Determine which lines should be highlighted
            var highlightRanges: [(start: Int, length: Int)] = []

            if multipleQuotes {
                // Multiple quotes at different positions
                highlightRanges = [
                    (start: 3, length: 4),
                    (start: 15, length: 3),
                    (start: 28, length: 5)
                ]
            } else {
                // Single quote
                highlightRanges = [(start: 8, length: 5)]
            }

            for paragraphLength in paragraphLengths {
                for _ in 0..<paragraphLength {
                    guard currentY + lineHeight < textArea.maxY else { break }

                    // Check if this line is in a highlight range
                    let shouldHighlight = highlightRanges.contains { range in
                        lineIndex >= range.start && lineIndex < range.start + range.length
                    }

                    let lineRect = CGRect(
                        x: textArea.minX,
                        y: currentY,
                        width: textArea.width * CGFloat.random(in: 0.85...1.0),
                        height: lineHeight
                    )

                    // Draw highlight background
                    if shouldHighlight {
                        highlightColor.setFill()
                        ctx.fill(lineRect)
                    }

                    // Draw simulated text line
                    textColor.setFill()
                    let textRect = CGRect(
                        x: lineRect.minX,
                        y: lineRect.minY + 8,
                        width: lineRect.width,
                        height: lineRect.height - 8
                    )

                    // Draw thin rectangles to simulate text
                    drawTextSimulation(in: textRect, context: ctx, isBlurry: lowConfidence)

                    currentY += lineHeight + lineSpacing
                    lineIndex += 1
                }

                // Paragraph break
                currentY += lineHeight
            }

            // Add underlines for some marked passages (second marking style)
            if !multipleQuotes {
                let quoteText = "Attention grows where you choose to return."
                let quoteTextRect = CGRect(
                    x: textArea.minX,
                    y: textArea.minY + lineHeight * 21 + lineSpacing * 21,
                    width: textArea.width * 0.86,
                    height: 64
                )

                backgroundColor.setFill()
                ctx.fill(quoteTextRect.insetBy(dx: -8, dy: -6))

                let quoteAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 34, weight: .regular),
                    .foregroundColor: textColor
                ]
                quoteText.draw(in: quoteTextRect, withAttributes: quoteAttributes)

                let underlineY = quoteTextRect.maxY + 6
                let underlineColor: UIColor = lowConfidence ? .systemGray : .red
                underlineColor.setStroke()
                ctx.setLineWidth(4)
                ctx.move(to: CGPoint(x: textArea.minX, y: underlineY))
                ctx.addLine(to: CGPoint(x: textArea.minX + textArea.width * 0.75, y: underlineY))
                ctx.strokePath()
            }

            // Add margin note if multipleQuotes
            if multipleQuotes {
                let noteColor: UIColor = .systemBlue
                noteColor.setFill()

                let noteRect = CGRect(
                    x: size.width - margins + 10,
                    y: textArea.minY + 100,
                    width: margins - 20,
                    height: 60
                )

                // Draw small text simulation for margin note
                for i in 0..<3 {
                    let lineRect = CGRect(
                        x: noteRect.minX,
                        y: noteRect.minY + CGFloat(i) * 18,
                        width: noteRect.width * CGFloat.random(in: 0.5...0.9),
                        height: 12
                    )
                    ctx.fill(lineRect)
                }
            }

            // Add blur effect for low confidence
            if lowConfidence {
                // Simulate blur by adding semi-transparent overlay
                UIColor.white.withAlphaComponent(0.3).setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }

            // Add page number
            let pageNumber = "\(42 + index)"
            let pageNumberRect = CGRect(
                x: size.width / 2 - 20,
                y: size.height - margins + 20,
                width: 40,
                height: 24
            )

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]

            pageNumber.draw(in: pageNumberRect, withAttributes: attributes)
        }
    }

    /// Draw simulated text using small rectangles
    private static func drawTextSimulation(in rect: CGRect, context: CGContext, isBlurry: Bool) {
        // Create word-like shapes
        var currentX = rect.minX
        let wordSpacing: CGFloat = 12

        while currentX < rect.maxX - 30 {
            let wordWidth = CGFloat.random(in: 20...60)
            let wordHeight = rect.height * 0.6

            if isBlurry {
                // Blurry effect: use multiple overlapping lighter rectangles
                context.setAlpha(0.4)
                for offset in [-2, 0, 2] {
                    let wordRect = CGRect(
                        x: currentX + CGFloat(offset),
                        y: rect.minY + (rect.height - wordHeight) / 2,
                        width: wordWidth,
                        height: wordHeight
                    )
                    context.fill(wordRect)
                }
                context.setAlpha(1.0)
            } else {
                let wordRect = CGRect(
                    x: currentX,
                    y: rect.minY + (rect.height - wordHeight) / 2,
                    width: wordWidth,
                    height: wordHeight
                )
                context.fill(wordRect)
            }

            currentX += wordWidth + wordSpacing
        }
    }

    // MARK: - Specific Test Images

    /// Image representing a book cover for metadata extraction testing
    static var bookCoverImage: UIImage {
        let size = CGSize(width: 800, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext

            // Gradient background
            let colors = [
                UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0).cgColor,
                UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1.0).cgColor
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )
            guard let gradient else { return }
            ctx.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )

            // Title area
            let titleRect = CGRect(x: 50, y: 200, width: size.width - 100, height: 150)
            drawTitleSimulation(in: titleRect, context: ctx, text: "ATOMIC HABITS")

            // Author area
            let authorRect = CGRect(x: 100, y: 800, width: size.width - 200, height: 40)
            drawTextSimulation(in: authorRect, context: ctx, isBlurry: false)
        }
    }

    private static func drawTitleSimulation(in rect: CGRect, context: CGContext, text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 48),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        text.draw(in: rect, withAttributes: attributes)
    }
}
