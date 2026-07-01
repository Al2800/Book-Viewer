import Foundation
import UIKit

@testable import BookQuotes

extension TestFixtures {
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
}
