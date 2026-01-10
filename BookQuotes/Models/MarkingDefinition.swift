import Foundation
import SwiftData

// MARK: - MarkingDefinition Model

/// User-defined marking vocabulary for personalized quote extraction.
/// Each reader has their own annotation system - this model captures that.
@Model
final class MarkingDefinition {
    // MARK: - Identity

    @Attribute(.unique) var id: UUID

    // MARK: - Definition Properties

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

    // MARK: - Timestamps

    var dateCreated: Date

    // MARK: - Relationships

    /// Quotes extracted with this marking type
    @Relationship(inverse: \Quote.customMarkingDefinition)
    var quotes: [Quote]

    // MARK: - Initialization

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

// MARK: - System Defaults

extension MarkingDefinition {
    /// Pre-populated marking definitions that users can customize or disable
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
            icon: "underline",
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
            icon: "chevron.left.forwardslash.chevron.right",
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
    @MainActor
    static func seedDefaults(in context: ModelContext) {
        let descriptor = FetchDescriptor<MarkingDefinition>(
            predicate: #Predicate { $0.isSystemDefault }
        )

        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (index, template) in systemDefaults.enumerated() {
            let definition = MarkingDefinition(
                name: template.name,
                visualDescription: template.visualDescription,
                meaning: template.meaning,
                icon: template.icon,
                colorName: template.colorName
            )
            definition.isSystemDefault = true
            definition.sortOrder = index
            context.insert(definition)
        }
    }
}
