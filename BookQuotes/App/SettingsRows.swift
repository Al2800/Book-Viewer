import SwiftUI

struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .sectionHeaderStyle()

            VStack(spacing: Spacing.sm) {
                content()
            }
        }
        .padding(Spacing.lg)
        .paperCard()
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let trailingIcon: String?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        trailingIcon: String? = "chevron.right"
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailingIcon = trailingIcon
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Circle()
                            .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                    }

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(icon: String, title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.backgroundSecondary)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(Color.quoteBorder.opacity(0.6), lineWidth: Stroke.hairline.width)
                        }

                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .toggleStyle(.switch)
    }
}

struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
        }
        .fieldChrome()
    }
}
