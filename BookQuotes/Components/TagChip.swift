import SwiftUI
import SwiftData

// MARK: - TagChip

/// Small chip component for displaying a tag with optional selection and remove button.
/// Features Stripe-level polish: selection animations, press states, and haptic feedback.
struct TagChip: View {

    // MARK: - Properties

    let tag: Tag

    /// Whether the tag is currently selected
    var isSelected: Bool = false

    /// Action when tapped
    var onTap: (() -> Void)?

    /// Action when remove button is tapped
    var onRemove: (() -> Void)?

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(tag.name)
                .font(.caption)
                .fontWeight(isSelected ? .medium : .regular)
                .lineLimit(1)

            if let onRemove = onRemove {
                Button {
                    HapticManager.light()
                    withAnimation(.quickSpring) {
                        onRemove()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(Capsule())
        .contentShape(Capsule())
        // Selection animation
        .animation(reduceMotion ? .none : .snappy, value: isSelected)
        // Press state
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
        .onTapGesture {
            if onTap != nil {
                HapticManager.light()
            }
            onTap?()
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            guard onTap != nil else { return }
            withAnimation(.quickSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - Styling

    private var tagColor: Color {
        CollectionColor(rawValue: tag.colorName)?.color ?? .blue
    }

    private var backgroundColor: Color {
        if isSelected {
            return tagColor
        } else {
            return tagColor.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else {
            return tagColor
        }
    }
}

// MARK: - TagChipText

/// Simple text-based tag chip (for use when Tag model isn't needed).
/// Features selection animation and press feedback.
struct TagChipText: View {

    // MARK: - Properties

    let text: String
    var color: Color = .blue
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(isSelected ? .medium : .regular)
            .lineLimit(1)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? color : color.opacity(0.15))
            .foregroundStyle(isSelected ? .white : color)
            .clipShape(Capsule())
            .contentShape(Capsule())
            // Selection animation
            .animation(reduceMotion ? .none : .snappy, value: isSelected)
            // Press state
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(reduceMotion ? .none : .quickSpring, value: isPressed)
            .onTapGesture {
                if onTap != nil {
                    HapticManager.light()
                }
                onTap?()
            }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                guard onTap != nil else { return }
                withAnimation(.quickSpring) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

// MARK: - TagInputField

/// Text field for creating new tags inline.
struct TagInputField: View {

    // MARK: - Properties

    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "tag")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .font(.caption)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.backgroundSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - TagsFlowLayout

/// Flow layout for displaying tags that wrap to multiple lines.
struct TagsFlowLayout: View {

    // MARK: - Properties

    let tags: [Tag]
    var isSelectable: Bool = false
    @Binding var selectedTagIds: Set<UUID>
    var onRemove: ((Tag) -> Void)?

    // MARK: - Body

    var body: some View {
        FlowLayout(spacing: Spacing.sm) {
            ForEach(tags) { tag in
                TagChip(
                    tag: tag,
                    isSelected: selectedTagIds.contains(tag.id),
                    onTap: isSelectable ? { toggleSelection(tag.id) } : nil,
                    onRemove: onRemove != nil ? { onRemove?(tag) } : nil
                )
            }
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedTagIds.contains(id) {
            selectedTagIds.remove(id)
        } else {
            selectedTagIds.insert(id)
        }
    }
}

// MARK: - FlowLayout

/// Layout that arranges views in rows, wrapping to the next line when needed.
struct FlowLayout: Layout {

    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            let position = arrangement.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private struct ArrangementResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            // Move to next line if needed
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            maxX = max(maxX, currentX + size.width)
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return ArrangementResult(
            size: CGSize(width: maxX, height: currentY + lineHeight),
            positions: positions
        )
    }
}

// MARK: - Preview

#Preview("Tag Chips") {
    VStack(spacing: 20) {
        Text("Normal Tags").font(.headline)
        HStack {
            TagChipText(text: "inspiration", color: .blue)
            TagChipText(text: "productivity", color: .green)
            TagChipText(text: "wisdom", color: .purple)
        }

        Text("Selected Tags").font(.headline)
        HStack {
            TagChipText(text: "inspiration", color: .blue, isSelected: true)
            TagChipText(text: "productivity", color: .green)
        }

        Text("With Remove Button").font(.headline)
        HStack {
            TagChipText(text: "removable", color: .orange)
        }
    }
    .padding()
}

#Preview("Flow Layout") {
    let tags = ["inspiration", "productivity", "wisdom", "books", "reading", "quotes", "motivation", "self-improvement"]

    FlowLayout(spacing: 8) {
        ForEach(tags, id: \.self) { tag in
            TagChipText(text: tag, color: .blue)
        }
    }
    .padding()
}

#Preview("Tag Input") {
    @Previewable @State var text = ""

    TagInputField(text: $text, placeholder: "Add tag...", onSubmit: {})
        .padding()
}
