import SwiftUI
import SwiftData

// MARK: - MarkingDefinitionsView

/// View for managing marking definitions - the user's annotation vocabulary.
/// Shows all marking types with enable/disable toggles, reordering, and editing.
struct MarkingDefinitionsView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode

    // MARK: - Queries

    @Query(sort: \MarkingDefinition.sortOrder) private var markings: [MarkingDefinition]

    // MARK: - State

    @State private var showAddSheet = false
    @State private var editingMarking: MarkingDefinition?
    @State private var markingToDelete: MarkingDefinition?
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        List {
            markingsSection
            addSection
            infoSection
        }
        .navigationTitle("Marking Styles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MarkingDefinitionEditorSheet(marking: nil) { newMarking in
                addMarking(newMarking)
            }
        }
        .sheet(item: $editingMarking) { marking in
            MarkingDefinitionEditorSheet(marking: marking) { _ in
                // Changes are saved automatically via @Bindable
            }
        }
        .confirmationDialog(
            "Delete Marking",
            isPresented: $showDeleteConfirmation,
            presenting: markingToDelete
        ) { marking in
            Button("Delete \"\(marking.name)\"", role: .destructive) {
                deleteMarking(marking)
            }
            Button("Cancel", role: .cancel) {}
        } message: { marking in
            Text("This will remove \"\(marking.name)\" from your vocabulary. Quotes using this marking will keep their text but lose the marking association.")
        }
        .onAppear {
            seedDefaultsIfNeeded()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var markingsSection: some View {
        Section {
            ForEach(markings) { marking in
                MarkingDefinitionRow(
                    marking: marking,
                    isEditing: editMode?.wrappedValue.isEditing ?? false
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if !(editMode?.wrappedValue.isEditing ?? false) {
                        editingMarking = marking
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !marking.isSystemDefault {
                        Button("Delete", role: .destructive) {
                            markingToDelete = marking
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .onMove(perform: moveMarkings)
            .onDelete(perform: deleteMarkings)
        } header: {
            HStack {
                Text("Your Marking Vocabulary")
                Spacer()
                Text("\(enabledCount) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("The AI looks for these patterns when extracting quotes from your book photos.")
        }
    }

    @ViewBuilder
    private var addSection: some View {
        Section {
            Button {
                showAddSheet = true
            } label: {
                Label("Add Custom Marking", systemImage: "plus.circle.fill")
            }
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Tip: Describe your markings accurately")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                }

                Text("The visual description helps the AI recognize your annotation style. Be specific about colors, shapes, and placement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Computed Properties

    private var enabledCount: Int {
        markings.filter(\.isEnabled).count
    }

    // MARK: - Actions

    private func seedDefaultsIfNeeded() {
        guard markings.isEmpty else { return }
        MarkingDefinition.seedDefaults(in: modelContext)
    }

    private func addMarking(_ marking: MarkingDefinition) {
        marking.sortOrder = markings.count
        modelContext.insert(marking)
    }

    private func moveMarkings(from source: IndexSet, to destination: Int) {
        var reorderedMarkings = markings
        reorderedMarkings.move(fromOffsets: source, toOffset: destination)

        for (index, marking) in reorderedMarkings.enumerated() {
            marking.sortOrder = index
        }
    }

    private func deleteMarkings(at offsets: IndexSet) {
        for index in offsets {
            let marking = markings[index]
            // Only delete non-system defaults
            if !marking.isSystemDefault {
                modelContext.delete(marking)
            }
        }
    }

    private func deleteMarking(_ marking: MarkingDefinition) {
        modelContext.delete(marking)
    }
}

// MARK: - Simple Editor Sheet (placeholder for full MarkingDefinitionEditor)

/// Temporary editor sheet until full MarkingDefinitionEditor is implemented.
/// Provides basic editing of marking properties.
private struct MarkingDefinitionEditorSheet: View {
    let marking: MarkingDefinition?
    let onSave: (MarkingDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var visualDescription: String = ""
    @State private var meaning: String = ""
    @State private var icon: String = "pencil.line"
    @State private var colorName: String = "blue"

    private let availableIcons = [
        "underline", "highlighter", "pencil.line", "note.text",
        "sidebar.leading", "circle", "asterisk", "questionmark",
        "exclamationmark", "star.fill", "heart.fill", "bookmark.fill",
        "chevron.left.forwardslash.chevron.right", "arrow.right"
    ]

    private let availableColors = [
        "red", "orange", "yellow", "green", "mint", "teal",
        "cyan", "blue", "indigo", "purple", "pink", "brown", "gray"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Marking name", text: $name)
                }

                Section("Meaning") {
                    TextField("What this marking means to you", text: $meaning)
                }

                Section("Visual Description") {
                    TextField("How the marking looks on the page", text: $visualDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            Button {
                                icon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.system(size: 20))
                                    .frame(width: 44, height: 44)
                                    .background(icon == iconName ? selectedColor.opacity(0.2) : Color.clear)
                                    .foregroundStyle(icon == iconName ? selectedColor : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                colorName = color
                            } label: {
                                Circle()
                                    .fill(colorFor(color))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if colorName == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
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
                        saveMarking()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let marking = marking {
                    name = marking.name
                    visualDescription = marking.visualDescription
                    meaning = marking.meaning
                    icon = marking.icon
                    colorName = marking.colorName
                }
            }
        }
    }

    private var selectedColor: Color {
        colorFor(colorName)
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

    private func saveMarking() {
        if let existing = marking {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.visualDescription = visualDescription.trimmingCharacters(in: .whitespaces)
            existing.meaning = meaning.trimmingCharacters(in: .whitespaces)
            existing.icon = icon
            existing.colorName = colorName
            onSave(existing)
        } else {
            let newMarking = MarkingDefinition(
                name: name.trimmingCharacters(in: .whitespaces),
                visualDescription: visualDescription.trimmingCharacters(in: .whitespaces),
                meaning: meaning.trimmingCharacters(in: .whitespaces),
                icon: icon,
                colorName: colorName
            )
            onSave(newMarking)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MarkingDefinitionsView()
    }
    .modelContainer(for: MarkingDefinition.self, inMemory: true)
}
