struct TagRowPresentation {
    let tag: Tag

    var name: String {
        tag.name
    }

    var quoteCountText: String {
        "\(tag.quoteCount)"
    }

    var collectionColor: CollectionColor {
        CollectionColor(rawValue: tag.colorName) ?? .blue
    }
}
