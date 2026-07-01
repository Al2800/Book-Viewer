@testable import BookQuotes

extension TestFixtures {
    // MARK: - Marking Definitions

    static func markingDefinition(
        name: String = "Underline",
        visualDescription: String = "Single line under text",
        meaning: String = "Important passage",
        icon: String = "underline",
        colorName: String = "blue",
        isSystemDefault: Bool = true
    ) -> MarkingDefinition {
        let definition = MarkingDefinition(
            name: name,
            visualDescription: visualDescription,
            meaning: meaning,
            icon: icon,
            colorName: colorName
        )
        definition.isSystemDefault = isSystemDefault
        return definition
    }

    static var allSystemMarkings: [MarkingDefinition] {
        MarkingDefinition.systemDefaults
    }

    // MARK: - Collections

    struct CollectionBuilder {
        var name: String = "Favorites"
        var icon: String = "star"
        var colorName: String = "blue"
        var collectionDescription: String? = "Favorite quotes and books"
        var sortOrder: Int = 0
        var books: [Book] = []
        var quotes: [Quote] = []

        func build() -> Collection {
            let collection = Collection(name: name, icon: icon, colorName: colorName)
            collection.collectionDescription = collectionDescription
            collection.sortOrder = sortOrder
            collection.books = books
            collection.quotes = quotes
            return collection
        }
    }

    static func collection(_ configure: (inout CollectionBuilder) -> Void = { _ in }) -> Collection {
        var builder = CollectionBuilder()
        configure(&builder)
        return builder.build()
    }

    static var favoritesCollection: Collection { collection() }

    // MARK: - Tags

    struct TagBuilder {
        var name: String = "productivity"
        var colorName: String = "blue"
        var books: [Book] = []
        var quotes: [Quote] = []

        func build() -> Tag {
            let tag = Tag(name: name, colorName: colorName)
            tag.books = books
            tag.quotes = quotes
            return tag
        }
    }

    static func tag(_ configure: (inout TagBuilder) -> Void = { _ in }) -> Tag {
        var builder = TagBuilder()
        configure(&builder)
        return builder.build()
    }

    static var productivityTag: Tag { tag() }
}
