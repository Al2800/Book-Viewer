import SwiftUI

// MARK: - MarkingTypeBadge

/// Badge displaying a marking type with icon and color.
/// Features subtle entrance animation and optional tap interaction.
struct MarkingTypeBadge: View {

    // MARK: - Properties

    /// The marking type enum to display
    var markingType: MarkingType?

    /// Optional custom marking definition (takes precedence)
    var customMarking: MarkingDefinition?

    /// Badge style
    var style: Style = .default

    /// Optional tap action
    var onTap: (() -> Void)?

    // MARK: - State

    @State private var hasAppeared = false
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Styles

    enum Style {
        case `default`  // Filled capsule
        case outline    // Outlined capsule
        case compact    // Just icon and text, no background
    }

    // MARK: - Computed

    private var displayName: String {
        customMarking?.name ?? markingType?.displayName ?? "Unknown"
    }

    private var iconName: String {
        customMarking?.icon ?? markingType?.systemImage ?? "pencil.line"
    }

    private var badgeColor: Color {
        if let customMarking = customMarking {
            return colorFor(name: customMarking.colorName)
        }
        return markingType?.color ?? .gray
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .default:
                defaultBadge
            case .outline:
                outlineBadge
            case .compact:
                compactBadge
            }
        }
        // Interactive state
        .scaleEffect(isPressed ? 0.95 : 1.0)
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.8)
        .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
        // Tap handling
        .onTapGesture {
            guard let onTap = onTap else { return }
            HapticManager.light()
            onTap()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            guard onTap != nil else { return }
            withAnimation(.quickSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Badge Styles

    private var defaultBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(badgeColor.opacity(0.15))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
    }

    private var outlineBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption2)
            Text(displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .overlay {
            Capsule()
                .stroke(badgeColor.opacity(0.5), lineWidth: 1)
        }
        .foregroundStyle(badgeColor)
    }

    private var compactBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.caption)
            Text(displayName)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Color Mapping

    private func colorFor(name: String) -> Color {
        switch name.lowercased() {
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
        case "gray", "grey": return .gray
        default: return .blue
        }
    }
}

// MARK: - MarkingType Extension

extension MarkingType {
    /// Color associated with the marking type
    var color: Color {
        switch self {
        case .underline: return .blue
        case .doubleUnderline: return .purple
        case .marginLine: return .green
        case .highlight: return .yellow
        case .bracket: return .orange
        case .marginNote: return .gray
        case .mixed: return .teal
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        Text("Default Style").font(.headline)
        HStack {
            MarkingTypeBadge(markingType: .underline)
            MarkingTypeBadge(markingType: .highlight)
            MarkingTypeBadge(markingType: .marginNote)
        }

        Text("Outline Style").font(.headline)
        HStack {
            MarkingTypeBadge(markingType: .underline, style: .outline)
            MarkingTypeBadge(markingType: .highlight, style: .outline)
        }

        Text("Compact Style").font(.headline)
        HStack {
            MarkingTypeBadge(markingType: .underline, style: .compact)
            MarkingTypeBadge(markingType: .highlight, style: .compact)
        }
    }
    .padding()
}
