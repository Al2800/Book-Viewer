import Foundation
import SwiftData

// MARK: - Tag Model

@Model
final class Tag {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    /// Tag name (unique, case-insensitive)
    @Attribute(.unique) var name: String

    // MARK: - Timestamps

    var dateCreated: Date

    // MARK: - Relationships

    var quotes: [Quote]

    // MARK: - Computed

    var quoteCount: Int { quotes.count }

    // MARK: - Initialization

    init(name: String) {
        self.id = UUID()
        self.name = name.lowercased().trimmingCharacters(in: .whitespaces)
        self.dateCreated = Date()
        self.quotes = []
    }
}
