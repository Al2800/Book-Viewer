import SwiftUI
import SwiftData

// MARK: - CollectionsView

/// Grid view showing all user collections with quote counts and cover previews.
struct CollectionsView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries

    @Query(sort: \Collection.sortOrder) private var collections: [Collection]

    // MARK: - State

    @State private var showCreateSheet = false
    @State private var selectedCollection: Collection?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .background(Color.backgroundPrimary)
                .navigationTitle("Collections")
                .navigationDestination(for: Collection.self) { collection in
                    CollectionDetailView(collection: collection)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Create Collection")
                        .accessibilityIdentifier(AccessibilityIdentifiers.Collections.createButton)
                    }
                }
                .sheet(isPresented: $showCreateSheet) {
                    CollectionEditorSheet(mode: .create)
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if collections.isEmpty {
            emptyState
        } else {
            collectionGrid
        }
    }

    // MARK: - Collection Grid

    private var collectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: Spacing.lg) {
                ForEach(collections) { collection in
                    NavigationLink(value: collection) {
                        CollectionCard(collection: collection)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityIdentifiers.Collections.collectionRow)
                }
            }
            .padding(Spacing.lg)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: Spacing.lg)]
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "folder.badge.plus",
            title: "No Collections Yet",
            message: "Create collections to organize quotes across books by topic, theme, or project.",
            action: ("Create Collection", { showCreateSheet = true })
        )
        .accessibilityIdentifier(AccessibilityIdentifiers.Collections.emptyState)
    }
}

// Note: CollectionDetailView is implemented in CollectionDetailView.swift

// MARK: - CollectionEditorSheet Placeholder

/// Placeholder for CollectionEditorSheet (implemented in separate file).
struct CollectionEditorSheet: View {
    enum Mode {
        case create
        case edit(Collection)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var icon = "folder"
    @State private var colorName = "ink"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    SettingsSectionCard(title: "Name") {
                        TextField("Name", text: $name)
                            .fieldChrome()
                            .accessibilityIdentifier(AccessibilityIdentifiers.Collections.nameField)
                    }

                    SettingsSectionCard(title: "Color") {
                        ColorSwatchGrid(selectedColorName: $colorName)
                    }

                    SettingsSectionCard(title: "Icon") {
                        IconPicker(selectedIcon: $icon, colorName: colorName)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle(isCreateMode ? "New Collection" : "Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreateMode ? "Create" : "Save") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let collection) = mode {
                    name = collection.name
                    icon = collection.icon
                    colorName = collection.colorName
                }
            }
        }
    }

    private var isCreateMode: Bool {
        if case .create = mode { return true }
        return false
    }

    private func save() {
        switch mode {
        case .create:
            let collection = Collection(name: name, icon: icon, colorName: colorName)
            modelContext.insert(collection)
        case .edit(let collection):
            collection.name = name
            collection.icon = icon
            collection.colorName = colorName
            collection.dateModified = Date()
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - IconPicker

/// Simple icon picker for collections.
private struct IconPicker: View {
    @Binding var selectedIcon: String
    let colorName: String

    private let icons = [
        "folder", "folder.fill",
        "star", "star.fill",
        "heart", "heart.fill",
        "bookmark", "bookmark.fill",
        "flag", "flag.fill",
        "tag", "tag.fill",
        "book", "book.closed",
        "quote.opening", "text.quote",
        "lightbulb", "brain",
        "graduationcap", "pencil",
        "doc.text", "list.bullet",
        "checkmark.circle", "exclamationmark.circle"
    ]

    private var selectionColor: Color {
        CollectionColor.named(colorName).color
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Spacing.sm) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(
                            selectedIcon == icon
                                ? selectionColor.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        .foregroundStyle(
                            selectedIcon == icon
                                ? selectionColor
                                : .secondary
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview("Collections Grid") {
    CollectionsView()
        .modelContainer(for: Collection.self, inMemory: true)
}

#Preview("Empty State") {
    CollectionsView()
        .modelContainer(for: Collection.self, inMemory: true)
}

#Preview("Create Sheet") {
    CollectionEditorSheet(mode: .create)
        .modelContainer(for: Collection.self, inMemory: true)
}
