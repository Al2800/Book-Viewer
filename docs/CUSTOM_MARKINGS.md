# Custom Marking Definitions

## Overview

Every reader has their own annotation system. Some use single underlines for important passages and double underlines for critical ones. Others use wavy lines for disagreement, asterisks for action items, or brackets for definitions.

BookQuotes allows users to define their own marking vocabulary, which gets injected into the AI prompt for personalized extraction.

---

## User Stories

> "I use a single underline for interesting quotes, but a double underline means I strongly agree. Wavy underlines mean I disagree with the author."

> "When I put an asterisk in the margin, it means this is an action item. A question mark means I need to research this further."

> "I bracket definitions and circle key terms. My margin notes are always in red pen."

---

## Feature Design

### Marking Definition Model

```swift
@Model
final class MarkingDefinition {
    @Attribute(.unique) var id: UUID

    /// User-facing name for this marking type
    var name: String

    /// Description of what this marking looks like visually
    var visualDescription: String

    /// What this marking means to the user (semantic intent)
    var meaning: String

    /// SF Symbol icon for UI display
    var icon: String

    /// Color for UI display
    var colorName: String

    /// Whether this is a system default or user-created
    var isSystemDefault: Bool

    /// Whether to include in extraction prompts
    var isEnabled: Bool

    /// Display order in lists
    var sortOrder: Int

    /// Quotes extracted with this marking type
    @Relationship(inverse: \Quote.customMarkingDefinition)
    var quotes: [Quote]

    var dateCreated: Date

    init(
        name: String,
        visualDescription: String,
        meaning: String,
        icon: String = "pencil.line",
        colorName: String = "blue"
    ) {
        self.id = UUID()
        self.name = name
        self.visualDescription = visualDescription
        self.meaning = meaning
        self.icon = icon
        self.colorName = colorName
        self.isSystemDefault = false
        self.isEnabled = true
        self.sortOrder = 0
        self.quotes = []
        self.dateCreated = Date()
    }
}
```

### System Default Markings

Pre-populated marking definitions that users can customize or disable:

```swift
extension MarkingDefinition {
    static let systemDefaults: [MarkingDefinition] = [
        MarkingDefinition(
            name: "Underline",
            visualDescription: "Single straight line drawn under text",
            meaning: "Important or memorable passage",
            icon: "underline",
            colorName: "blue"
        ),
        MarkingDefinition(
            name: "Double Underline",
            visualDescription: "Two parallel lines drawn under text",
            meaning: "Very important or critical passage",
            icon: "underline.badge.2",
            colorName: "purple"
        ),
        MarkingDefinition(
            name: "Margin Line",
            visualDescription: "Vertical line drawn in the margin next to a paragraph",
            meaning: "Entire paragraph is noteworthy",
            icon: "sidebar.leading",
            colorName: "green"
        ),
        MarkingDefinition(
            name: "Highlight",
            visualDescription: "Text colored with highlighter or marker pen",
            meaning: "Key passage to remember",
            icon: "highlighter",
            colorName: "yellow"
        ),
        MarkingDefinition(
            name: "Bracket",
            visualDescription: "Square or curly brackets around text",
            meaning: "Discrete section of interest",
            icon: "brackets",
            colorName: "orange"
        ),
        MarkingDefinition(
            name: "Margin Note",
            visualDescription: "Handwritten text in the margin",
            meaning: "Personal thought or reaction",
            icon: "note.text",
            colorName: "gray"
        ),
        MarkingDefinition(
            name: "Circle",
            visualDescription: "Circle drawn around a word or phrase",
            meaning: "Key term or concept",
            icon: "circle",
            colorName: "red"
        ),
        MarkingDefinition(
            name: "Asterisk",
            visualDescription: "Star or asterisk symbol in margin",
            meaning: "Action item or follow-up needed",
            icon: "asterisk",
            colorName: "pink"
        ),
        MarkingDefinition(
            name: "Question Mark",
            visualDescription: "Question mark in margin next to text",
            meaning: "Confusion or need to research further",
            icon: "questionmark",
            colorName: "teal"
        )
    ]

    /// Seed database with defaults on first launch
    static func seedDefaults(in context: ModelContext) {
        let descriptor = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate { $0.isSystemDefault }
        )

        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (index, definition) in systemDefaults.enumerated() {
            let copy = MarkingDefinition(
                name: definition.name,
                visualDescription: definition.visualDescription,
                meaning: definition.meaning,
                icon: definition.icon,
                colorName: definition.colorName
            )
            copy.isSystemDefault = true
            copy.sortOrder = index
            context.insert(copy)
        }
    }
}
```

### Updated Quote Model

```swift
@Model
final class Quote {
    // ... existing properties ...

    /// The marking type used (legacy enum for migration)
    var markingType: MarkingType

    /// Custom marking definition (new, preferred)
    var customMarkingDefinition: MarkingDefinition?

    /// Computed display name for the marking
    var markingDisplayName: String {
        customMarkingDefinition?.name ?? markingType.displayName
    }
}
```

---

## Dynamic Prompt Generation

The user's enabled marking definitions are compiled into the extraction prompt:

```swift
extension GeminiService {
    /// Generate quote extraction prompt with user's custom marking definitions
    func buildQuoteExtractionPrompt(markings: [MarkingDefinition]) -> String {
        let enabledMarkings = markings.filter { $0.isEnabled }

        // Build marking descriptions
        let markingDescriptions = enabledMarkings.map { marking in
            """
            - **\(marking.name)**: \(marking.visualDescription)
              Meaning: \(marking.meaning)
            """
        }.joined(separator: "\n")

        // Build marking type enum for JSON
        let markingTypes = enabledMarkings.map {
            "\"\(marking.name.lowercased().replacingOccurrences(of: " ", with: "_"))\""
        }.joined(separator: " | ")

        return """
        Analyze this book page image to extract marked/highlighted passages.

        The reader uses the following marking system:

        \(markingDescriptions)

        Return a JSON object:
        {
          "quotes": [
            {
              "text": "The exact text that was marked",
              "pageNumber": 42,
              "marginNote": "Any handwritten note near this passage, or null",
              "markingType": \(markingTypes),
              "confidence": 0.92
            }
          ],
          "pageNumber": 42,
          "processingNotes": "Optional notes about extraction quality"
        }

        Rules for extraction:
        1. Extract the COMPLETE marked passage - include full sentences
        2. Match the marking type to the user's defined vocabulary above
        3. If a passage has multiple marking types, use the primary/most prominent one
        4. Preserve original formatting (line breaks where meaningful)
        5. Transcribe any handwritten margin notes as accurately as possible
        6. If page number is visible (corners/headers), include it
        7. If multiple separate passages are marked, return each as separate quote
        8. confidence should be 0.0-1.0 for each quote's accuracy

        Respond with ONLY the JSON object, no markdown formatting.
        """
    }
}
```

---

## Settings UI

### Marking Definitions List

```swift
struct MarkingDefinitionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MarkingDefinition.sortOrder) private var markings: [MarkingDefinition]

    @State private var showAddSheet = false
    @State private var editingMarking: MarkingDefinition?

    var body: some View {
        List {
            Section {
                ForEach(markings) { marking in
                    MarkingDefinitionRow(marking: marking)
                        .swipeActions(edge: .trailing) {
                            if !marking.isSystemDefault {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(marking)
                                }
                            }
                        }
                        .onTapGesture {
                            editingMarking = marking
                        }
                }
                .onMove { from, to in
                    // Reorder markings
                }
            } header: {
                Text("Your Marking Vocabulary")
            } footer: {
                Text("Define how you mark up books. The AI will look for these specific patterns when extracting quotes.")
            }

            Section {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Custom Marking", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Marking Styles")
        .sheet(isPresented: $showAddSheet) {
            MarkingDefinitionEditor(marking: nil)
        }
        .sheet(item: $editingMarking) { marking in
            MarkingDefinitionEditor(marking: marking)
        }
    }
}

struct MarkingDefinitionRow: View {
    @Bindable var marking: MarkingDefinition

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: marking.icon)
                .font(.title3)
                .foregroundStyle(Color(marking.colorName))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(marking.name)
                        .font(.body)

                    if marking.isSystemDefault {
                        Text("Default")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Text(marking.meaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $marking.isEnabled)
                .labelsHidden()
        }
    }
}
```

### Marking Definition Editor

```swift
struct MarkingDefinitionEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let marking: MarkingDefinition?

    @State private var name: String = ""
    @State private var visualDescription: String = ""
    @State private var meaning: String = ""
    @State private var selectedIcon: String = "pencil.line"
    @State private var selectedColor: String = "blue"

    private var isEditing: Bool { marking != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., Wavy Underline", text: $name)
                }

                Section {
                    TextField("e.g., Wavy or squiggly line under text", text: $visualDescription, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Visual Description")
                } footer: {
                    Text("Describe what this marking looks like on the page. Be specific so the AI can identify it.")
                }

                Section {
                    TextField("e.g., I disagree with this statement", text: $meaning, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Meaning")
                } footer: {
                    Text("What does this marking mean to you? This helps categorize your quotes.")
                }

                Section("Appearance") {
                    iconPicker
                    colorPicker
                }

                if isEditing && !(marking?.isSystemDefault ?? false) {
                    Section {
                        Button("Delete Marking", role: .destructive) {
                            if let marking = marking {
                                modelContext.delete(marking)
                            }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Marking" : "New Marking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || visualDescription.isEmpty)
                }
            }
            .onAppear {
                if let marking = marking {
                    name = marking.name
                    visualDescription = marking.visualDescription
                    meaning = marking.meaning
                    selectedIcon = marking.icon
                    selectedColor = marking.colorName
                }
            }
        }
    }

    private var iconPicker: some View {
        // Grid of relevant SF Symbols
        let icons = [
            "underline", "strikethrough", "pencil.line",
            "highlighter", "sidebar.leading", "brackets",
            "circle", "asterisk", "questionmark", "exclamationmark",
            "checkmark", "xmark", "arrow.right", "star",
            "heart", "bookmark", "tag", "note.text"
        ]

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        selectedIcon = icon
                    }
            }
        }
    }

    private var colorPicker: some View {
        let colors = ["red", "orange", "yellow", "green", "mint",
                      "teal", "cyan", "blue", "indigo", "purple", "pink", "gray"]

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(colors, id: \.self) { colorName in
                Circle()
                    .fill(Color(colorName))
                    .frame(width: 32, height: 32)
                    .overlay {
                        if selectedColor == colorName {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        selectedColor = colorName
                    }
            }
        }
    }

    private func save() {
        if let marking = marking {
            // Update existing
            marking.name = name
            marking.visualDescription = visualDescription
            marking.meaning = meaning
            marking.icon = selectedIcon
            marking.colorName = selectedColor
        } else {
            // Create new
            let newMarking = MarkingDefinition(
                name: name,
                visualDescription: visualDescription,
                meaning: meaning,
                icon: selectedIcon,
                colorName: selectedColor
            )
            modelContext.insert(newMarking)
        }
    }
}
```

---

## Example Custom Markings

### Academic Reader

| Name | Visual | Meaning |
|------|--------|---------|
| Primary Source | Double underline | Direct evidence from original source |
| Secondary Analysis | Single underline | Author's interpretation |
| Methodology | Bracket | Research method described |
| Citation Needed | Question mark | Claim needs verification |
| For Paper | Asterisk | Use in my paper |

### Fiction Reader

| Name | Visual | Meaning |
|------|--------|---------|
| Beautiful Prose | Wavy underline | Lovely writing to savor |
| Foreshadowing | Circle | Hints at future events |
| Character Insight | Margin line | Reveals character depth |
| Theme | Double underline | Core thematic statement |
| Favorite Quote | Star in margin | Share-worthy passage |

### Business Reader

| Name | Visual | Meaning |
|------|--------|---------|
| Action Item | Asterisk | Implement this |
| Key Metric | Circle | Important number/stat |
| Framework | Bracket | Model or framework |
| Counter-argument | Wavy underline | I disagree |
| Share with Team | Arrow | Discuss in meeting |

---

## Onboarding Flow

For new users, offer quick-start templates:

```swift
enum MarkingTemplate: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case academic = "Academic"
    case creative = "Creative Writing"
    case business = "Business"
    case custom = "Start from Scratch"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .standard: return "Underlines, highlights, and margin notes"
        case .academic: return "Source analysis, citations, methodology tracking"
        case .creative: return "Beautiful prose, character insights, themes"
        case .business: return "Action items, metrics, frameworks"
        case .custom: return "Define your own system"
        }
    }

    var markings: [MarkingDefinition] {
        switch self {
        case .standard:
            return MarkingDefinition.systemDefaults
        case .academic:
            return academicMarkings
        case .creative:
            return creativeMarkings
        case .business:
            return businessMarkings
        case .custom:
            return []
        }
    }
}
```

---

## Migration from Static Enum

For existing data using the `MarkingType` enum:

```swift
extension Quote {
    /// Migrate legacy marking type to custom definition
    func migrateToCustomMarking(definitions: [MarkingDefinition]) {
        guard customMarkingDefinition == nil else { return }

        // Find matching definition by name
        let legacyName = markingType.displayName
        if let match = definitions.first(where: {
            $0.name.lowercased() == legacyName.lowercased()
        }) {
            customMarkingDefinition = match
        }
    }
}

// Run migration on app launch
func migrateMarkings(context: ModelContext) {
    let quotes = try? context.fetch(FetchDescriptor<Quote>())
    let definitions = try? context.fetch(FetchDescriptor<MarkingDefinition>())

    guard let quotes = quotes, let definitions = definitions else { return }

    for quote in quotes {
        quote.migrateToCustomMarking(definitions: definitions)
    }
}
```

---

## Summary

Custom marking definitions transform BookQuotes from a generic OCR tool into a personalized annotation partner that understands your unique reading style. The AI prompt dynamically adapts to extract exactly what you mark, using your vocabulary and meanings.
