import Foundation
import UIKit

@testable import BookQuotes

extension TestFixtures {
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
}
