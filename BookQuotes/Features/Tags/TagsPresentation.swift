struct TagsPresentation {
    let tags: [Tag]

    var totalUses: Int {
        tags.reduce(0) { $0 + $1.quoteCount }
    }

    func filteredTags(searchText: String) -> [Tag] {
        guard !searchText.isEmpty else { return tags }

        return tags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}
