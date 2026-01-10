import SwiftUI

// MARK: - FilterPill

/// A dismissable pill-shaped tag showing an active filter.
/// Used in ActiveFiltersBar to display and remove individual filters.
struct FilterPill: View {
    // MARK: - Properties

    let label: String
    let icon: String
    let color: Color
    let onRemove: () -> Void

    // MARK: - Initialization

    init(
        label: String,
        icon: String,
        color: Color = .accentColor,
        onRemove: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.color = color
        self.onRemove = onRemove
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(label)
                .font(.caption)
                .lineLimit(1)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .contentShape(Capsule())
    }
}

// MARK: - FilterPillStyle

/// Different visual styles for filter pills
enum FilterPillStyle {
    case book
    case markingType
    case date
    case favorite
    case confidence

    var icon: String {
        switch self {
        case .book: return "book.closed"
        case .markingType: return "pencil.line"
        case .date: return "calendar"
        case .favorite: return "star.fill"
        case .confidence: return "checkmark.seal"
        }
    }

    var color: Color {
        switch self {
        case .book: return .blue
        case .markingType: return .purple
        case .date: return .orange
        case .favorite: return .yellow
        case .confidence: return .green
        }
    }
}

// MARK: - Convenience Initializers

extension FilterPill {
    /// Create a filter pill with a predefined style
    init(
        label: String,
        style: FilterPillStyle,
        onRemove: @escaping () -> Void
    ) {
        self.init(
            label: label,
            icon: style.icon,
            color: style.color,
            onRemove: onRemove
        )
    }
}

// MARK: - Preview

#Preview("Filter Pills") {
    VStack(spacing: 16) {
        // Individual pills
        HStack {
            FilterPill(
                label: "Atomic Habits",
                style: .book
            ) {
                print("Remove book")
            }

            FilterPill(
                label: "Underline",
                style: .markingType
            ) {
                print("Remove marking")
            }
        }

        HStack {
            FilterPill(
                label: "This Week",
                style: .date
            ) {
                print("Remove date")
            }

            FilterPill(
                label: "Favorites",
                style: .favorite
            ) {
                print("Remove favorites")
            }
        }

        FilterPill(
            label: "High Confidence",
            style: .confidence
        ) {
            print("Remove confidence")
        }

        // Custom color
        FilterPill(
            label: "Custom Filter",
            icon: "slider.horizontal.3",
            color: .teal
        ) {
            print("Remove custom")
        }
    }
    .padding()
}
