import SwiftUI
import SwiftData

// MARK: - MarkingDefinitionRow

/// A row displaying a marking definition with toggle and visual indicators.
/// Used in MarkingDefinitionsView for managing the marking vocabulary.
struct MarkingDefinitionRow: View {
    // MARK: - Properties

    @Bindable var marking: MarkingDefinition

    /// Whether editing is in progress (disables toggle)
    var isEditing: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Icon with color
            iconView

            // Text content
            textContent

            Spacer()

            // Toggle for enabled state
            if !isEditing {
                enableToggle
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Components

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(markingColor.opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: marking.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(markingColor)
        }
    }

    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(marking.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(marking.isEnabled ? .primary : .secondary)

                if marking.isSystemDefault {
                    Text("Default")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text(marking.meaning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var enableToggle: some View {
        Toggle("Enabled", isOn: $marking.isEnabled)
            .labelsHidden()
            .tint(markingColor)
    }

    // MARK: - Helpers

    private var markingColor: Color {
        switch marking.colorName {
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

#Preview {
    List {
        MarkingDefinitionRow(
            marking: {
                let m = MarkingDefinition(
                    name: "Underline",
                    visualDescription: "Single straight line under text",
                    meaning: "Important passage",
                    icon: "underline",
                    colorName: "blue"
                )
                m.isSystemDefault = true
                return m
            }()
        )

        MarkingDefinitionRow(
            marking: MarkingDefinition(
                name: "My Custom Mark",
                visualDescription: "Custom marking style",
                meaning: "Personal annotation",
                icon: "star.fill",
                colorName: "orange"
            )
        )

        MarkingDefinitionRow(
            marking: {
                let m = MarkingDefinition(
                    name: "Disabled Mark",
                    visualDescription: "Not active",
                    meaning: "Won't be extracted",
                    icon: "xmark",
                    colorName: "gray"
                )
                m.isEnabled = false
                return m
            }()
        )
    }
}
