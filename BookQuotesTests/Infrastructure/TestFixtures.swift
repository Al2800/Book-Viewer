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
}
