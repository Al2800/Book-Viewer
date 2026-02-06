import Foundation
import SwiftData
import UIKit

@testable import BookQuotes

/// Factory methods for creating real test data.
/// All methods return actual model instances, not mocks.
enum TestFixtures {
    // MARK: - Books

    struct BookBuilder {
        var title: String = "Atomic Habits"
        var author: String = "James Clear"
        var subtitle: String? = "An Easy & Proven Way to Build Good Habits"
        var isbn: String? = "978-0735211292"
        var status: ReadingStatus = .currentlyReading
        var coverThumbnailData: Data? = nil

        func build() -> Book {
            let book = Book(title: title, author: author)
            book.subtitle = subtitle
            book.isbn = isbn
            book.status = status
            book.coverThumbnailData = coverThumbnailData ?? Self.defaultCoverImage
            return book
        }

        static let defaultCoverImage: Data = {
            let size = CGSize(width: 100, height: 150)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                UIColor.systemBlue.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            return image.jpegData(compressionQuality: 0.8) ?? Data()
        }()
    }

    static func book(_ configure: (inout BookBuilder) -> Void = { _ in }) -> Book {
        var builder = BookBuilder()
        configure(&builder)
        return builder.build()
    }

    static var atomicHabits: Book { book() }

    static var deepWork: Book {
        book { builder in
            builder.title = "Deep Work"
            builder.author = "Cal Newport"
            builder.subtitle = "Rules for Focused Success in a Distracted World"
            builder.status = .finished
        }
    }

    static var thinkingFastAndSlow: Book {
        book { builder in
            builder.title = "Thinking, Fast and Slow"
            builder.author = "Daniel Kahneman"
            builder.status = .wantToRead
        }
    }

    // MARK: - Quotes

    struct QuoteBuilder {
        var text: String = "Every action you take is a vote for the type of person you wish to become."
        var pageNumber: Int? = 38
        var marginNote: String? = nil
        var markingType: MarkingType = .underline
        var confidence: Double? = 0.95
        var isFavorite: Bool = false
        var book: Book? = nil

        func build() -> Quote {
            let quote = Quote(text: text)
            quote.pageNumber = pageNumber
            quote.marginNote = marginNote
            quote.markingType = markingType
            quote.confidence = confidence
            quote.isFavorite = isFavorite
            quote.book = book
            return quote
        }
    }

    static func quote(_ configure: (inout QuoteBuilder) -> Void = { _ in }) -> Quote {
        var builder = QuoteBuilder()
        configure(&builder)
        return builder.build()
    }

    static var voteQuote: Quote { quote() }

    static var habitsQuote: Quote {
        quote { builder in
            builder.text = "You do not rise to the level of your goals. You fall to the level of your systems."
            builder.pageNumber = 27
            builder.marginNote = "Key insight!"
            builder.markingType = .doubleUnderline
        }
    }

    static var lowConfidenceQuote: Quote {
        quote { builder in
            builder.text = "Partially readable text here..."
            builder.confidence = 0.45
            builder.marginNote = "Hard to read"
        }
    }

    // MARK: - Marking Definitions

    static func markingDefinition(
        name: String = "Underline",
        visualDescription: String = "Single line under text",
        meaning: String = "Important passage",
        icon: String = "underline",
        colorName: String = "blue",
        isSystemDefault: Bool = true
    ) -> MarkingDefinition {
        let definition = MarkingDefinition(
            name: name,
            visualDescription: visualDescription,
            meaning: meaning,
            icon: icon,
            colorName: colorName
        )
        definition.isSystemDefault = isSystemDefault
        return definition
    }

    static var allSystemMarkings: [MarkingDefinition] {
        MarkingDefinition.systemDefaults
    }

    // MARK: - Collections

    struct CollectionBuilder {
        var name: String = "Favorites"
        var icon: String = "star"
        var colorName: String = "blue"
        var collectionDescription: String? = "Favorite quotes and books"
        var sortOrder: Int = 0
        var books: [Book] = []
        var quotes: [Quote] = []

        func build() -> Collection {
            let collection = Collection(name: name, icon: icon, colorName: colorName)
            collection.collectionDescription = collectionDescription
            collection.sortOrder = sortOrder
            collection.books = books
            collection.quotes = quotes
            return collection
        }
    }

    static func collection(_ configure: (inout CollectionBuilder) -> Void = { _ in }) -> Collection {
        var builder = CollectionBuilder()
        configure(&builder)
        return builder.build()
    }

    static var favoritesCollection: Collection { collection() }

    // MARK: - Tags

    struct TagBuilder {
        var name: String = "productivity"
        var colorName: String = "blue"
        var books: [Book] = []
        var quotes: [Quote] = []

        func build() -> Tag {
            let tag = Tag(name: name, colorName: colorName)
            tag.books = books
            tag.quotes = quotes
            return tag
        }
    }

    static func tag(_ configure: (inout TagBuilder) -> Void = { _ in }) -> Tag {
        var builder = TagBuilder()
        configure(&builder)
        return builder.build()
    }

    static var productivityTag: Tag { tag() }

    // MARK: - Capture Sessions

    struct CaptureSessionBuilder {
        var book: Book? = nil
        var status: CaptureSession.SessionStatus = .capturing
        var dateStarted: Date = Date()
        var dateCompleted: Date? = nil
        var totalPages: Int = 0
        var processedPages: Int = 0
        var failedPages: Int = 0
        var captures: [PageCapture] = []

        func build() -> CaptureSession {
            let session = CaptureSession(book: book)
            session.status = status
            session.dateStarted = dateStarted
            session.dateCompleted = dateCompleted
            session.totalPages = totalPages
            session.processedPages = processedPages
            session.failedPages = failedPages
            session.captures = captures
            return session
        }
    }

    static func captureSession(_ configure: (inout CaptureSessionBuilder) -> Void = { _ in }) -> CaptureSession {
        var builder = CaptureSessionBuilder()
        configure(&builder)
        return builder.build()
    }

    // MARK: - Page Captures

    struct PageCaptureBuilder {
        var imagePath: String = "captures/test/\(UUID().uuidString).jpg"
        var session: CaptureSession? = nil
        var orderIndex: Int = 0
        var status: PageCapture.CaptureStatus = .pending
        var errorMessage: String? = nil
        var dateCreated: Date = Date()
        var dateProcessed: Date? = nil
        var extractedQuoteCount: Int = 0
        var averageConfidence: Double? = nil
        var detectedPageNumber: Int? = nil
        var qualityScore: Double? = nil
        var qualityWarningsDismissed: Bool = false

        func build() -> PageCapture {
            let capture = PageCapture(imagePath: imagePath, session: session)
            capture.orderIndex = orderIndex
            capture.status = status
            capture.errorMessage = errorMessage
            capture.dateCreated = dateCreated
            capture.dateProcessed = dateProcessed
            capture.extractedQuoteCount = extractedQuoteCount
            capture.averageConfidence = averageConfidence
            capture.detectedPageNumber = detectedPageNumber
            capture.qualityScore = qualityScore
            capture.qualityWarningsDismissed = qualityWarningsDismissed
            return capture
        }
    }

    static func pageCapture(_ configure: (inout PageCaptureBuilder) -> Void = { _ in }) -> PageCapture {
        var builder = PageCaptureBuilder()
        configure(&builder)
        return builder.build()
    }

    // MARK: - Capture Queue Items

    struct CaptureQueueItemBuilder {
        var book: Book = TestFixtures.book()
        var imagePath: String = "CaptureQueue/\(UUID().uuidString).jpg"
        var thumbnailData: Data? = nil
        var priority: Int = 0
        var status: QueueItemStatus = .pending
        var retryCount: Int = 0
        var lastError: String? = nil
        var dateQueued: Date = Date()
        var dateLastAttempt: Date? = nil
        var dateCompleted: Date? = nil
        var extractedQuotes: [Quote]? = nil

        func build() -> CaptureQueueItem {
            let item = CaptureQueueItem(
                book: book,
                imagePath: imagePath,
                thumbnailData: thumbnailData,
                priority: priority
            )
            item.status = status
            item.retryCount = retryCount
            item.lastError = lastError
            item.dateQueued = dateQueued
            item.dateLastAttempt = dateLastAttempt
            item.dateCompleted = dateCompleted
            item.extractedQuotes = extractedQuotes
            return item
        }
    }

    static func captureQueueItem(
        _ configure: (inout CaptureQueueItemBuilder) -> Void = { _ in }
    ) -> CaptureQueueItem {
        var builder = CaptureQueueItemBuilder()
        configure(&builder)
        return builder.build()
    }

    // MARK: - Search Test Data

    /// Generate a large dataset for performance testing.
    static func largeBookCollection(bookCount: Int, quotesPerBook: Int) -> [Book] {
        let words = [
            "happiness", "success", "mindset", "growth", "learning",
            "wisdom", "focus", "habits", "discipline", "motivation"
        ]

        return (0..<bookCount).map { index in
            let book = Book(title: "Test Book \(index)", author: "Author \(index % 10)")

            for page in 0..<quotesPerBook {
                let randomWords = (0..<10).compactMap { _ in words.randomElement() }
                let quote = Quote(text: randomWords.joined(separator: " "))
                quote.pageNumber = page + 1
                quote.book = book
            }

            return book
        }
    }

    static func searchFilters(_ configure: (inout SearchFilters) -> Void = { _ in }) -> SearchFilters {
        var filters = SearchFilters()
        configure(&filters)
        return filters
    }

    // MARK: - Images

    enum TestImages {
        static var bookPage: Data {
            generateBookPageImage()
        }

        static var bookCover: Data {
            generateBookCoverImage()
        }

        static var blurryPage: Data {
            generateBlurryImage()
        }

        private static func generateBookPageImage() -> Data {
            let size = CGSize(width: 400, height: 600)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                UIColor.black.setFill()
                for index in 0..<20 {
                    let y = CGFloat(50 + index * 25)
                    context.fill(CGRect(x: 30, y: y, width: CGFloat.random(in: 200...350), height: 3))
                }

                UIColor.yellow.withAlphaComponent(0.5).setFill()
                context.fill(CGRect(x: 30, y: 150, width: 300, height: 20))
            }
            return image.jpegData(compressionQuality: 0.9) ?? Data()
        }

        private static func generateBookCoverImage() -> Data {
            let size = CGSize(width: 300, height: 450)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                let colors = [UIColor.systemIndigo.cgColor, UIColor.systemPurple.cgColor]
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors as CFArray,
                    locations: [0, 1]
                )

                if let gradient {
                    context.cgContext.drawLinearGradient(
                        gradient,
                        start: .zero,
                        end: CGPoint(x: 0, y: size.height),
                        options: []
                    )
                }

                UIColor.white.withAlphaComponent(0.9).setFill()
                context.fill(CGRect(x: 20, y: 150, width: 260, height: 30))
                context.fill(CGRect(x: 40, y: 200, width: 220, height: 15))
            }
            return image.jpegData(compressionQuality: 0.9) ?? Data()
        }

        private static func generateBlurryImage() -> Data {
            let size = CGSize(width: 100, height: 150)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                UIColor.gray.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            return image.jpegData(compressionQuality: 0.1) ?? Data()
        }
    }

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

                // Background
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

                // Decorative shapes (deterministic).
                UIColor.white.withAlphaComponent(0.12).setFill()
                ctx.fill(CGRect(x: 28, y: 28, width: 90, height: 90))
                ctx.fill(CGRect(x: size.width - 140, y: size.height - 170, width: 112, height: 112))

                // Foreground card for text.
                let card = CGRect(x: 24, y: 110, width: size.width - 48, height: size.height - 220)
                let cardPath = UIBezierPath(roundedRect: card, cornerRadius: 22)
                UIColor.white.withAlphaComponent(0.92).setFill()
                cardPath.fill()

                // Optional slight rotation for one fixture to exercise OCR tolerance.
                if style == .slightlyRotated {
                    cg.saveGState()
                    let center = CGPoint(x: card.midX, y: card.midY)
                    cg.translateBy(x: center.x, y: center.y)
                    cg.rotate(by: -0.03)
                    cg.translateBy(x: -center.x, y: -center.y)
                }

                // Typography
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

                // Badge for one variant.
                if style == .mixedCaseBadge {
                    let badge = CGRect(x: card.minX + 18, y: card.minY + 18, width: 110, height: 32)
                    let badgePath = UIBezierPath(roundedRect: badge, cornerRadius: 16)
                    UIColor.black.withAlphaComponent(0.08).setFill()
                    badgePath.fill()
                    let badgeText = "Bestseller"
                    drawText(
                        badgeText,
                        in: badge.insetBy(dx: 10, dy: 6),
                        font: preferredFont(named: "HelveticaNeue-Medium", fallback: .systemFont(ofSize: 14, weight: .medium)),
                        color: textColor,
                        alignment: .center
                    )
                }

                // Layout: keep generous line spacing so OCR prefers correct tokenization.
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
