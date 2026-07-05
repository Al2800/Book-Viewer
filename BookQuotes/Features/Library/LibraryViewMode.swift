import Foundation

enum LibraryViewMode: String, Equatable {
    case grid
    case list

    var systemImageName: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        }
    }

    var summaryText: String {
        switch self {
        case .grid:
            return "Grid View"
        case .list:
            return "List View"
        }
    }
}

// MARK: - Library Sort Order

/// User-selectable ordering for the library's Books section.
enum LibrarySortOrder: String, CaseIterable, Identifiable {
    case recent
    case title
    case author

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recent:
            return "Recently Added"
        case .title:
            return "Title"
        case .author:
            return "Author"
        }
    }

    func sorted(_ books: [Book]) -> [Book] {
        switch self {
        case .recent:
            return books.sorted { $0.dateAdded > $1.dateAdded }
        case .title:
            return books.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .author:
            return books.sorted {
                $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending
            }
        }
    }
}
