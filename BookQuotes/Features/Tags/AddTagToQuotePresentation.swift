struct AddTagToQuotePresentation {
    let allTags: [Tag]
    let currentTags: [Tag]

    var availableTags: [Tag] {
        let currentTagIds = Set(currentTags.map(\.id))
        return allTags.filter { !currentTagIds.contains($0.id) }
    }
}
