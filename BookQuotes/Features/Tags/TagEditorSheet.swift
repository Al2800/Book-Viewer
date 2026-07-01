import SwiftUI
import SwiftData

/// Sheet for creating or editing a tag.
struct TagEditorSheet: View {
    let mode: TagEditorMode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var colorName = "blue"

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Name") {
                    TextField("Enter tag name", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier(AccessibilityIdentifiers.Tags.nameField)
                }

                Section("Color") {
                    colorPicker
                }
            }
            .navigationTitle(modePresentation.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(modePresentation.confirmationActionTitle) {
                        save()
                    }
                    .disabled(!tagEditorDraft.canSave)
                }
            }
            .onAppear {
                if case .edit(let tag) = mode {
                    name = tag.name
                    colorName = tag.colorName
                }
            }
        }
    }

    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
            ForEach(CollectionColor.allCases) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)
                    .overlay {
                        if colorName == color.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        colorName = color.rawValue
                    }
            }
        }
    }

    private var modePresentation: TagEditorModePresentation {
        TagEditorModePresentation(mode: mode)
    }

    private func save() {
        switch mode {
        case .create:
            modelContext.insert(tagEditorDraft.makeTag())
        case .edit(let tag):
            tagEditorDraft.apply(to: tag)
        }

        try? modelContext.save()
        dismiss()
    }

    private var tagEditorDraft: TagEditorDraft {
        TagEditorDraft(name: name, colorName: colorName)
    }
}
