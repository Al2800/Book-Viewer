import SwiftUI

// MARK: - FilterPill

/// A dismissable pill-shaped tag showing an active filter.
/// Features Stripe-level polish: remove animation, press feedback, and haptics.
struct FilterPill: View {
    // MARK: - Properties

    let label: String
    let icon: String
    let color: Color
    let onRemove: () -> Void

    // MARK: - State

    @State private var isPressed = false
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption2)

            Text(label)
                .font(.caption)
                .lineLimit(1)

            Button {
                HapticManager.light()
                withAnimation(.quickSpring) {
                    onRemove()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color.opacity(0.7))
            }
            .buttonStyle(FilterRemoveButtonStyle())
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .contentShape(Capsule())
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.8)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            withAnimation(.smoothSpring) {
                hasAppeared = true
            }
        }
        // Removal transition
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.5).combined(with: .opacity)
        ))
    }
}

// MARK: - Filter Remove Button Style

/// Subtle button style for the X remove button in filter pills.
private struct FilterRemoveButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(2)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: configuration.isPressed)
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
