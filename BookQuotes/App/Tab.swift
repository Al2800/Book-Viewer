import Foundation

/// Available tabs in the current TestFlight navigation.
enum Tab: Hashable, CaseIterable, Identifiable {
    case library
    case capture
    case studio
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .library: return "Library"
        case .capture: return "Capture"
        case .studio: return "Studio"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .library: return "books.vertical"
        case .capture: return "camera"
        case .studio: return "sparkles.rectangle.stack"
        case .settings: return "gear"
        }
    }
}

/// Primary destinations in the v2 product reset.
enum V2Tab: Hashable, CaseIterable, Identifiable {
    case reading
    case capture
    case explore

    var id: Self { self }

    var title: String {
        switch self {
        case .reading: return "Reading"
        case .capture: return "Capture"
        case .explore: return "Explore"
        }
    }

    var systemImage: String {
        switch self {
        case .reading: return "books.vertical"
        case .capture: return "camera"
        case .explore: return "magnifyingglass"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .reading: return "v2_reading_tab"
        case .capture: return "v2_capture_tab"
        case .explore: return "v2_explore_tab"
        }
    }
}

/// Gate for developing the new product structure without replacing the
/// current TestFlight experience until its release criteria are met.
enum ProductExperience {
    static let v2StorageKey = "product_experience_v2_enabled"
    static let v2LaunchArgument = "--product-experience-v2"

    static func usesV2(
        storedValue: Bool,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> Bool {
        storedValue || arguments.contains(v2LaunchArgument)
    }
}
