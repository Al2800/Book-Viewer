import SwiftUI
import SwiftData

// MARK: - MarkingDefinitionEditor

/// Full-featured editor for creating and editing marking definitions.
/// Provides icon/color pickers, field validation, and preview.
struct MarkingDefinitionEditor: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// The marking to edit, or nil for creating a new one
    let marking: MarkingDefinition?

    /// Callback when save completes
    var onSave: ((MarkingDefinition) -> Void)?

    // MARK: - State

    @State private var name: String = ""
    @State private var visualDescription: String = ""
    @State private var meaning: String = ""
    @State private var selectedIcon: String = "pencil.line"
    @State private var selectedColor: String = "blue"

    @State private var showIconPicker = false
    @State private var showValidationError = false

    // MARK: - Icon and Color Options

    private let iconOptions = [
        "underline", "strikethrough", "pencil.line", "highlighter",
        "sidebar.leading", "chevron.left.forwardslash.chevron.right",
        "circle", "asterisk", "questionmark", "exclamationmark",
        "checkmark", "star.fill", "heart.fill", "bookmark.fill",
        "arrow.right", "note.text", "square.and.pencil", "hand.draw"
    ]

    private let colorOptions = [
        "red", "orange", "yellow", "green", "mint", "teal",
        "cyan", "blue", "indigo", "purple", "pink", "brown", "gray"
    ]

    // MARK: - Initialization

    init(marking: MarkingDefinition? = nil, onSave: ((MarkingDefinition) -> Void)? = nil) {
        self.marking = marking
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                nameSection
                visualDescriptionSection
                meaningSection
                iconSection
                colorSection
            }
            .navigationTitle(marking == nil ? "New Marking" : "Edit Marking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadExistingData()
            }
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK") {}
            } message: {
                Text("Please fill in all required fields: Name, Visual Description, and Meaning.")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var previewSection: some View {
        Section {
            HStack {
                Spacer()
                markingPreview
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var markingPreview: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(currentColor.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: selectedIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(currentColor)
            }

            Text(name.isEmpty ? "Marking Name" : name)
                .font(.headline)
                .foregroundStyle(name.isEmpty ? .secondary : .primary)
        }
    }

    @ViewBuilder
    private var nameSection: some View {
        Section {
            TextField("e.g., Wavy Underline", text: $name)
                .textContentType(.name)
        } header: {
            HStack {
                Text("Name")
                Text("*")
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var visualDescriptionSection: some View {
        Section {
            TextField("e.g., Wavy or squiggly line under text", text: $visualDescription, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            HStack {
                Text("Visual Description")
                Text("*")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("Describe what this looks like on the page. Be specific for AI accuracy.")
        }
    }

    @ViewBuilder
    private var meaningSection: some View {
        Section {
            TextField("e.g., I disagree with this statement", text: $meaning, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            HStack {
                Text("Meaning")
                Text("*")
                    .foregroundStyle(.red)
            }
        } footer: {
            Text("What does this marking mean to you? This helps the AI understand your intent.")
        }
    }

    @ViewBuilder
    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedIcon == icon ? currentColor.opacity(0.15) : Color.clear)
                                .frame(width: 48, height: 48)

                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundStyle(selectedIcon == icon ? currentColor : .secondary)
                        }
                        .overlay {
                            if selectedIcon == icon {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(currentColor, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                ForEach(colorOptions, id: \.self) { colorName in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedColor = colorName
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(colorFor(colorName))
                                .frame(width: 36, height: 36)

                            if selectedColor == colorName {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 3)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .shadow(color: colorFor(colorName).opacity(0.4), radius: selectedColor == colorName ? 4 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !visualDescription.trimmingCharacters(in: .whitespaces).isEmpty &&
        !meaning.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func loadExistingData() {
        guard let marking = marking else { return }
        name = marking.name
        visualDescription = marking.visualDescription
        meaning = marking.meaning
        selectedIcon = marking.icon
        selectedColor = marking.colorName
    }

    private func save() {
        guard isValid else {
            showValidationError = true
            return
        }

        let savedMarking: MarkingDefinition

        if let existing = marking {
            // Update existing marking
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.visualDescription = visualDescription.trimmingCharacters(in: .whitespaces)
            existing.meaning = meaning.trimmingCharacters(in: .whitespaces)
            existing.icon = selectedIcon
            existing.colorName = selectedColor
            savedMarking = existing
        } else {
            // Create new marking
            let newMarking = MarkingDefinition(
                name: name.trimmingCharacters(in: .whitespaces),
                visualDescription: visualDescription.trimmingCharacters(in: .whitespaces),
                meaning: meaning.trimmingCharacters(in: .whitespaces),
                icon: selectedIcon,
                colorName: selectedColor
            )
            modelContext.insert(newMarking)
            savedMarking = newMarking
        }

        onSave?(savedMarking)
        dismiss()
    }

    // MARK: - Helpers

    private var currentColor: Color {
        colorFor(selectedColor)
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Preview

#Preview("New Marking") {
    MarkingDefinitionEditor()
        .modelContainer(for: MarkingDefinition.self, inMemory: true)
}

#Preview("Edit Marking") {
    let marking = MarkingDefinition(
        name: "Wavy Underline",
        visualDescription: "Wavy or squiggly line under text",
        meaning: "I disagree with this statement",
        icon: "underline",
        colorName: "red"
    )
    return MarkingDefinitionEditor(marking: marking)
        .modelContainer(for: MarkingDefinition.self, inMemory: true)
}
