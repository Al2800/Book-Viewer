struct TagEditorDraft {
    let name: String
    let colorName: String

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespaces).lowercased()
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func makeTag() -> Tag {
        Tag(name: normalizedName, colorName: colorName)
    }

    func apply(to tag: Tag) {
        tag.name = normalizedName
        tag.colorName = colorName
    }
}
