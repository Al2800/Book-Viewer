enum TagEditorMode {
    case create
    case edit(Tag)

    var isCreateMode: Bool {
        if case .create = self { return true }
        return false
    }
}

struct TagEditorModePresentation {
    let mode: TagEditorMode

    var navigationTitle: String {
        mode.isCreateMode ? "New Tag" : "Edit Tag"
    }

    var confirmationActionTitle: String {
        mode.isCreateMode ? "Create" : "Save"
    }
}
