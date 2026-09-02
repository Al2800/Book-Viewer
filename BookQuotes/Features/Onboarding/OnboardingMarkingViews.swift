import SwiftUI

struct MarkingTemplateSelector: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selectionState: OnboardingMarkingSelectionState

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            ForEach(MarkingType.configurableCases, id: \.self) { type in
                MarkingStyleOption(
                    type: type,
                    isSelected: selectionState.isSelected(type)
                ) {
                    selectionState.toggle(type)
                    HapticManager.light()
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible()),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
        )
    }
}

private struct MarkingStyleOption: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let type: MarkingType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: Spacing.md) {
                        markingIcon
                        markingLabel
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(spacing: Spacing.sm) {
                        markingIcon
                        markingLabel
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? Color.brand.opacity(0.1) : Color.backgroundSecondary)
            .foregroundStyle(isSelected ? Color.brand : Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var markingIcon: some View {
        Image(systemName: type.systemImage)
            .font(.uiLabel)
    }

    private var markingLabel: some View {
        Text(type.displayName)
            .font(dynamicTypeSize.isAccessibilitySize ? .body : .caption)
            .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
