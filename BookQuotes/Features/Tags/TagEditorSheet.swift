import SwiftUI
import SwiftData

/// Sheet for creating or editing a tag.
struct TagEditorSheet: View {
    let mode: TagEditorMode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var colorName = "ink"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    SettingsSectionCard(title: "Tag Name") {
                        TextField("Enter tag name", text: $name)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .fieldChrome()
                            .accessibilityIdentifier(AccessibilityIdentifiers.Tags.nameField)
                    }

                    SettingsSectionCard(title: "Color") {
                        ColorSwatchGrid(selectedColorName: $colorName)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.backgroundPrimary)
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

// MARK: - ColorSwatchGrid

/// Swatch grid for choosing a `CollectionColor` by its stored name.
/// Shared by the tag and collection editors.
struct ColorSwatchGrid: View {
    @Binding var selectedColorName: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
            ForEach(CollectionColor.allCases) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)
                    .overlay {
                        if selectedColorName == color.rawValue {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        selectedColorName = color.rawValue
                    }
                    .accessibilityLabel(color.displayName)
                    .accessibilityAddTraits(selectedColorName == color.rawValue ? [.isSelected] : [])
            }
        }
    }
}
