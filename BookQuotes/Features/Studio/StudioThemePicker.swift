import SwiftUI

// MARK: - StudioThemePicker

/// Horizontal theme selector bar with tactile preview swatches.
struct StudioThemePicker: View {
    @Binding var selectedTheme: StudioTheme
    @Binding var selectedAspect: StudioAspectRatio
    var showsAspectPicker: Bool = true

    var body: some View {
        VStack(spacing: Spacing.md) {
            if showsAspectPicker {
                StudioAspectRatioPicker(selectedAspect: $selectedAspect)
                    .padding(.horizontal, Spacing.lg)
            }

            // Theme Swatches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(StudioTheme.allCases) { theme in
                        Button {
                            HapticManager.selection()
                            withAnimation(.quickSpring) {
                                selectedTheme = theme
                            }
                        } label: {
                            VStack(spacing: Spacing.xxs) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .fill(theme.cardBackground)
                                        .frame(width: 58, height: 42)

                                    // Decorative inner accent stripe
                                    Rectangle()
                                        .fill(theme.accentColor)
                                        .frame(width: 3.5, height: 22)
                                        .offset(x: -18)

                                    if selectedTheme == theme {
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(Color.gildedAccent, lineWidth: 2)
                                    } else {
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(theme.borderColor, lineWidth: 1)
                                    }
                                }
                                .shadow(color: Color.black.opacity(selectedTheme == theme ? 0.2 : 0.04), radius: 3, y: 1)

                                Text(theme.displayName)
                                    .font(.caption2.weight(selectedTheme == theme ? .bold : .regular))
                                    .foregroundStyle(selectedTheme == theme ? Color.textPrimary : Color.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 66, height: 64)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(theme.displayName) theme")
                        .accessibilityAddTraits(selectedTheme == theme ? [.isSelected] : [])
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
}

// MARK: - StudioAspectRatioPicker

/// Pill selector for choosing aspect ratio format.
struct StudioAspectRatioPicker: View {
    @Binding var selectedAspect: StudioAspectRatio

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(StudioAspectRatio.allCases) { aspect in
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedAspect = aspect
                    }
                } label: {
                    Text(aspect.displayName)
                        .font(.caption.weight(selectedAspect == aspect ? .semibold : .regular))
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedAspect == aspect
                                ? AnyShapeStyle(Color.brand)
                                : AnyShapeStyle(Color.backgroundSecondary)
                        )
                        .foregroundStyle(selectedAspect == aspect ? Color.white : Color.textSecondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(aspect.displayName)
                .accessibilityAddTraits(selectedAspect == aspect ? [.isSelected] : [])
            }
        }
        .padding(Spacing.xxs)
        .background(Color.backgroundSecondary.opacity(0.6))
        .clipShape(Capsule())
    }
}
