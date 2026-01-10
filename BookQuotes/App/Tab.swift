import Foundation

/// Available tabs in the main navigation
enum Tab: Hashable, CaseIterable, Identifiable {
    case library
    case capture
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .library: return "Library"
        case .capture: return "Capture"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .library: return "books.vertical"
        case .capture: return "camera"
        case .settings: return "gear"
        }
    }
}
