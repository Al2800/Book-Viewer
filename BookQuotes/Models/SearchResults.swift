import Foundation
import SwiftUI

// MARK: - Search Results Container

/// Container for search results from FTS5 queries
struct SearchResults: Sendable {
    let quotes: [SearchQuoteResult]
    let books: [SearchBookResult]
    let query: String

    var isEmpty: Bool {
        quotes.isEmpty && books.isEmpty
    }

    var totalCount: Int {
        quotes.count + books.count
    }

    static let empty = SearchResults(quotes: [], books: [], query: "")
}

// MARK: - Quote Search Result

/// A quote match from FTS5 search with highlighting support
struct SearchQuoteResult: Identifiable, Sendable {
    let id: UUID
    let quoteId: UUID
    let bookId: UUID
    let snippet: String  // Pre-highlighted by FTS5 with <mark> tags
    let rank: Double

    init(quoteId: UUID, bookId: UUID, snippet: String, rank: Double) {
        self.id = UUID()
        self.quoteId = quoteId
        self.bookId = bookId
        self.snippet = snippet
        self.rank = rank
    }

    /// Convert FTS5 <mark> tags to AttributedString with highlighting
    var highlightedSnippet: AttributedString {
        var text = snippet
        var result = AttributedString()

        while let startRange = text.range(of: "<mark>") {
            // Add text before the mark
            let beforeMark = String(text[..<startRange.lowerBound])
            result.append(AttributedString(beforeMark))

            // Remove the opening tag
            text = String(text[startRange.upperBound...])

            // Find closing tag
            if let endRange = text.range(of: "</mark>") {
                let markedText = String(text[..<endRange.lowerBound])
                var highlighted = AttributedString(markedText)
                highlighted.backgroundColor = .yellow.opacity(0.4)
                highlighted.font = .body.bold()
                result.append(highlighted)
                text = String(text[endRange.upperBound...])
            }
        }

        // Add remaining text
        result.append(AttributedString(text))
        return result
    }

    /// Plain text without HTML tags
    var plainText: String {
        snippet
            .replacingOccurrences(of: "<mark>", with: "")
            .replacingOccurrences(of: "</mark>", with: "")
    }
}

// MARK: - Book Search Result

/// A book match from FTS5 search
struct SearchBookResult: Identifiable, Sendable {
    let id: UUID
    let bookId: UUID
    let titleSnippet: String
    let authorSnippet: String
    let rank: Double

    init(bookId: UUID, titleSnippet: String, authorSnippet: String, rank: Double) {
        self.id = UUID()
        self.bookId = bookId
        self.titleSnippet = titleSnippet
        self.authorSnippet = authorSnippet
        self.rank = rank
    }

    /// Highlighted title
    var highlightedTitle: AttributedString {
        convertToHighlighted(titleSnippet)
    }

    /// Highlighted author
    var highlightedAuthor: AttributedString {
        convertToHighlighted(authorSnippet)
    }

    private func convertToHighlighted(_ text: String) -> AttributedString {
        var remaining = text
        var result = AttributedString()

        while let startRange = remaining.range(of: "<mark>") {
            let beforeMark = String(remaining[..<startRange.lowerBound])
            result.append(AttributedString(beforeMark))
            remaining = String(remaining[startRange.upperBound...])

            if let endRange = remaining.range(of: "</mark>") {
                let markedText = String(remaining[..<endRange.lowerBound])
                var highlighted = AttributedString(markedText)
                highlighted.backgroundColor = .yellow.opacity(0.4)
                highlighted.font = .body.bold()
                result.append(highlighted)
                remaining = String(remaining[endRange.upperBound...])
            }
        }

        result.append(AttributedString(remaining))
        return result
    }
}

// MARK: - Search Error

/// Errors that can occur during search operations
enum SearchError: Error, LocalizedError {
    case databaseOpenFailed
    case tableCreationFailed
    case queryFailed(String)
    case indexingFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseOpenFailed:
            return "Failed to open search database"
        case .tableCreationFailed:
            return "Failed to create search tables"
        case .queryFailed(let detail):
            return "Search query failed: \(detail)"
        case .indexingFailed(let detail):
            return "Indexing failed: \(detail)"
        }
    }
}
