import Foundation

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case emptyTitle
    case emptyAuthor
    case emptyQuote
    case quoteTooShort
    case invalidRating

    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Book title cannot be empty"
        case .emptyAuthor: return "Author name cannot be empty"
        case .emptyQuote: return "Quote text cannot be empty"
        case .quoteTooShort: return "Quote must be at least 10 characters"
        case .invalidRating: return "Rating must be between 1 and 5"
        }
    }
}
