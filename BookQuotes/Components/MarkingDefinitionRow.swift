import SwiftUI
import SwiftData

// MARK: - MarkingDefinitionRow

/// A row displaying a marking definition with toggle and visual indicators.
/// Used in MarkingDefinitionsView for managing the marking vocabulary.
/// Features entrance animation and smooth toggle interactions.
struct MarkingDefinitionRow: View {
    // MARK: - Properties

    @Bindable var marking: MarkingDefinition

    /// Whether editing is in progress (disables toggle)
    var isEditing: Bool = false

    // MARK: - State

    @State private var hasAppeared = false
    @State private var iconScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.md) {
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
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : -10)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(markingColor.opacity(marking.isEnabled ? 0.15 : 0.08))
                .frame(width: 40, height: 40)

            Image(systemName: marking.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(marking.isEnabled ? markingColor : markingColor.opacity(0.5))
                .scaleEffect(iconScale)
        }
        .animation(reduceMotion ? .none : .snappy, value: marking.isEnabled)
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
            .onChange(of: marking.isEnabled) { _, newValue in
                HapticManager.light()
                // Icon bounce feedback
                guard !reduceMotion else { return }
                withAnimation(.quickSpring) {
                    iconScale = 1.15
                }
                withAnimation(.quickSpring.delay(0.1)) {
                    iconScale = 1.0
                }
            }
    }

    // MARK: - Helpers

    private var markingColor: Color {
        CollectionColor.named(marking.colorName).color
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
