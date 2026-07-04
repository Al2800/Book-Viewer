import Foundation
import SwiftData

// MARK: - Tag Model

@Model
final class Tag {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    /// Tag name (unique, case-insensitive)
    @Attribute(.unique) var name: String

    /// Color identifier (from predefined palette)
    var colorName: String

    // MARK: - Timestamps

    var dateCreated: Date

    // MARK: - Relationships

    var books: [Book]

    var quotes: [Quote]

    // MARK: - Computed

    var quoteCount: Int { quotes.count }

    // MARK: - Initialization

    init(name: String, colorName: String = "ink") {
        self.id = UUID()
        self.name = name.lowercased().trimmingCharacters(in: .whitespaces)
        self.colorName = colorName
        self.dateCreated = Date()
        self.books = []
        self.quotes = []
    }
}
