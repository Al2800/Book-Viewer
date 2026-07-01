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
