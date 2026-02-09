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
        .accessibilityIdentifier(AccessibilityIdentifiers.MarkingDefinitions.listView)
        .navigationTitle("Marking Styles")
        .scrollContentBackground(.hidden)
        .background(Color.backgroundPrimary)
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MarkingDefinitionEditor(marking: nil) { newMarking in
                addMarking(newMarking)
            }
        }
        .sheet(item: $editingMarking) { marking in
            MarkingDefinitionEditor(marking: marking)
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
                .padding(Spacing.md)
                .paperCard()
                .accessibilityIdentifier(AccessibilityIdentifiers.MarkingDefinitions.markingRow)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
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
                    .font(.sectionHeader)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("\(enabledCount) active")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        } footer: {
            Text("The AI looks for these patterns when extracting quotes from your book photos.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
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
            .accessibilityIdentifier(AccessibilityIdentifiers.MarkingDefinitions.addButton)
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paperCard()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
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
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(Spacing.md)
            .paperCard()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
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

// MARK: - Preview

#Preview {
    NavigationStack {
        MarkingDefinitionsView()
    }
    .modelContainer(for: MarkingDefinition.self, inMemory: true)
}
