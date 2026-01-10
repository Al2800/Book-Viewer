import SwiftUI

// MARK: - EmptyStateView

/// Reusable empty state view with icon, title, message, and optional action.
struct EmptyStateView: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let message: String

    /// Optional action button
    var action: (label: String, handler: () -> Void)?

    /// Style variant
    var style: Style = .default

    // MARK: - Styles

    enum Style {
        case `default`  // Centered, large icon
        case compact    // Smaller, inline
        case card       // With background card
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .default:
            defaultStyle
        case .compact:
            compactStyle
        case .card:
            cardStyle
        }
    }

    // MARK: - Default Style

    private var defaultStyle: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let action = action {
                Button(action.label) {
                    action.handler()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Compact Style

    private var compactStyle: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let action = action {
                Button(action.label) {
                    action.handler()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(Spacing.md)
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let action = action {
                Button(action.label) {
                    action.handler()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            Text("Default Style").font(.headline)
            EmptyStateView(
                icon: "books.vertical",
                title: "No Books Yet",
                message: "Capture your first book cover to start building your library.",
                action: ("Add Book", { print("Action tapped") })
            )
            .frame(height: 300)

            Divider()

            Text("Compact Style").font(.headline)
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                message: "Try different search terms",
                style: .compact
            )

            Divider()

            Text("Card Style").font(.headline)
            EmptyStateView(
                icon: "quote.opening",
                title: "No Quotes",
                message: "Capture some pages to add quotes.",
                action: ("Capture", {}),
                style: .card
            )
            .padding(.horizontal)
        }
    }
}
