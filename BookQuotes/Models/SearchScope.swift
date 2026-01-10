import Foundation

/// Search scope for filtering results
enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case books = "Books"
    case quotes = "Quotes"

    var id: String { rawValue }
}
