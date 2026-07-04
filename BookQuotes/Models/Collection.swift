import Foundation
import SwiftData
import SwiftUI

// MARK: - Collection Model

@Model
final class Collection {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Properties

    /// Collection name
    var name: String

    /// SF Symbol icon name
    var icon: String

    /// Color identifier (from predefined palette)
    var colorName: String

    /// Optional description
    var collectionDescription: String?

    // MARK: - Timestamps

    var dateCreated: Date
    var dateModified: Date

    // MARK: - Sorting

    /// Display order (lower = first)
    var sortOrder: Int

    // MARK: - Relationships

    var books: [Book]

    var quotes: [Quote]

    // MARK: - Computed

    var quoteCount: Int { quotes.count }

    // MARK: - Initialization

    init(name: String, icon: String = "folder", colorName: String = "ink") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.dateCreated = Date()
        self.dateModified = Date()
        self.sortOrder = 0
        self.books = []
        self.quotes = []
    }
}

// MARK: - Collection Colors

/// Muted "bookbinding" palette for collections and tags.
/// Each color lives in the asset catalog with a dark-mode variant,
/// tuned to sit beside the warm paper backgrounds.
enum CollectionColor: String, CaseIterable, Identifiable {
    case oxblood, forest, ink, mustard, plum, slate

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .oxblood: return Color("Oxblood")
        case .forest: return Color("Forest")
        case .ink: return Color("Ink")
        case .mustard: return Color("Mustard")
        case .plum: return Color("Plum")
        case .slate: return Color("Slate")
        }
    }

    var displayName: String { rawValue.capitalized }

    /// Resolve a stored color name, mapping legacy system-color names
    /// (from the pre-bookbinding rainbow palette) onto the muted palette
    /// so existing user data keeps a stable, sensible color.
    static func named(_ name: String) -> CollectionColor {
        if let color = CollectionColor(rawValue: name) {
            return color
        }
        switch name {
        case "red", "pink": return .oxblood
        case "green", "mint": return .forest
        case "teal", "cyan", "blue": return .ink
        case "orange", "yellow", "brown": return .mustard
        case "indigo", "purple": return .plum
        default: return .slate
        }
    }
}
