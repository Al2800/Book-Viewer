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

    @Relationship(inverse: \Book.collections)
    var books: [Book]

    @Relationship(inverse: \Quote.collections)
    var quotes: [Quote]

    // MARK: - Computed

    var quoteCount: Int { quotes.count }

    // MARK: - Initialization

    init(name: String, icon: String = "folder", colorName: String = "blue") {
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

enum CollectionColor: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown, gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}
