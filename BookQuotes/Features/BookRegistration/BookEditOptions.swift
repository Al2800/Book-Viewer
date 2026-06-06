import Foundation

// MARK: - Book Edit Options

enum BookEditOptions {
    static var genreOptions: [BookGenre] {
        BookGenre.allCases
    }

    static func genreLabel(for rawValue: String) -> String {
        guard !rawValue.isEmpty else { return "None" }
        return BookGenre(rawValue: rawValue)?.displayName ?? rawValue
    }
}

// MARK: - Book Genre

/// Common book genres for categorization.
enum BookGenre: String, CaseIterable {
    case fiction
    case nonFiction = "non-fiction"
    case sciFi = "science-fiction"
    case fantasy
    case mystery
    case thriller
    case romance
    case biography
    case selfHelp = "self-help"
    case business
    case history
    case science
    case philosophy
    case psychology
    case poetry
    case other

    var displayName: String {
        switch self {
        case .fiction: return "Fiction"
        case .nonFiction: return "Non-Fiction"
        case .sciFi: return "Science Fiction"
        case .fantasy: return "Fantasy"
        case .mystery: return "Mystery"
        case .thriller: return "Thriller"
        case .romance: return "Romance"
        case .biography: return "Biography"
        case .selfHelp: return "Self-Help"
        case .business: return "Business"
        case .history: return "History"
        case .science: return "Science"
        case .philosophy: return "Philosophy"
        case .psychology: return "Psychology"
        case .poetry: return "Poetry"
        case .other: return "Other"
        }
    }
}
