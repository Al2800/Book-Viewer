import SwiftUI

struct MarkingTemplateSelector: View {
    @State private var selectionState = OnboardingMarkingSelectionState()

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(MarkingType.allCases, id: \.self) { type in
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
}

private struct MarkingStyleOption: View {
    let type: MarkingType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: type.systemImage)
                    .font(.title2)

                Text(type.displayName)
                    .font(.caption)
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
}
