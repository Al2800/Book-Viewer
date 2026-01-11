import SwiftUI

// MARK: - SearchSuggestionsView

/// View displaying search suggestions as the user types
struct SearchSuggestionsView: View {

    // MARK: - Environment

    @Environment(SearchSuggestionsService.self) private var suggestionsService
    @State private var appeared = false

    // MARK: - Callbacks

    let onSelect: (String) -> Void
    let onClearHistory: () -> Void

    // MARK: - Body

    var body: some View {
        if shouldShowSuggestions {
            List {
                if suggestionsService.isLoading {
                    loadingRow
                }

                ForEach(Array(suggestionsService.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        onSelect(suggestion.text)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                    .listRowBackground(Color.clear)
                    .accessibleStaggeredEntrance(appeared: appeared, index: index)
                }

                // Clear history button if showing recent searches
                if hasRecentSuggestions {
                    clearHistoryButton
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .onAppear {
                appeared = true
            }
            .onDisappear {
                appeared = false
            }
            .accessibleAnimation(.accessibleSmoothSpring, value: suggestionsService.suggestions)
        }
    }

    // MARK: - Computed Properties

    private var shouldShowSuggestions: Bool {
        !suggestionsService.suggestions.isEmpty || suggestionsService.isLoading
    }

    private var hasRecentSuggestions: Bool {
        suggestionsService.suggestions.contains { $0.isRecent }
    }

    // MARK: - Subviews

    private var clearHistoryButton: some View {
        Button(role: .destructive) {
            HapticManager.warning()
            onClearHistory()
        } label: {
            HStack {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.error)

                Text("Clear Recent Searches")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.error)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.error.opacity(0.08))
            )
            .strokeBorder(.hairline, color: Color.error.opacity(0.3), cornerRadius: CornerRadius.md)
        }
        .buttonStyle(PressableButtonStyle(enableHaptic: false))
        .accessibilityLabel("Clear recent searches")
    }

    private var loadingRow: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(Color.accent)

            Text("Loading suggestions")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - SuggestionRow

private struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                iconBadge

                Text(suggestion.text)
                    .font(.bodyText)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                trailingContent
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(LinearGradient.surfaceGradient)
            )
            .strokeBorder(.hairline, color: Color.quoteBorder, cornerRadius: CornerRadius.md)
            .elevation(.xs, colorScheme: colorScheme)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(suggestion.text), \(suggestion.typeLabel)")
    }

    private var iconForeground: Color {
        switch suggestion {
        case .recent:
            return .textSecondary
        case .bookTitle:
            return .brand
        case .author:
            return .accent
        case .popularTerm:
            return .textSecondary
        }
    }

    private var iconBackground: Color {
        switch suggestion {
        case .recent, .popularTerm:
            return Color.backgroundTertiary
        case .bookTitle:
            return Color.brand.opacity(0.12)
        case .author:
            return Color.accent.opacity(0.12)
        }
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(iconBackground)
            Image(systemName: suggestion.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconForeground)
        }
        .frame(width: 28, height: 28)
    }

    @ViewBuilder
    private var trailingContent: some View {
        switch suggestion {
        case .recent:
            Image(systemName: "arrow.up.left")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textTertiary)

        case .bookTitle:
            suggestionTag(text: "Book", color: .brand)

        case .author:
            suggestionTag(text: "Author", color: .accent)

        case .popularTerm(_, let count):
            if count > 1 {
                suggestionTag(text: "\(count)", color: .textSecondary)
            }
        }
    }

    private func suggestionTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - DidYouMeanBanner

/// Banner suggesting a corrected search query for likely typos
struct DidYouMeanBanner: View {

    // MARK: - Properties

    let suggestion: String
    let onAccept: () -> Void

    // MARK: - State

    @State private var appeared = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accent)

            Text("Did you mean")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

            Button {
                onAccept()
            } label: {
                Text(suggestion)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.ghost)

            Spacer()

            Image(systemName: "arrow.right.circle")
                .font(.subheadline)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(LinearGradient.surfaceGradient)
        )
        .strokeBorder(.hairline, color: Color.quoteBorder, cornerRadius: CornerRadius.md)
        .elevation(.xs, colorScheme: colorScheme)
        .accessibleEntrance(appeared: appeared)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Preview

#Preview("Search Suggestions") {
    struct PreviewWrapper: View {
        private let suggestionsService: SearchSuggestionsService?

        init() {
            if let searchDB = try? SearchDatabase() {
                suggestionsService = SearchSuggestionsService(searchDB: searchDB)
            } else {
                suggestionsService = nil
            }
        }

        var body: some View {
            Group {
                if let suggestionsService {
                    VStack(spacing: 0) {
                        // Simulated search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("swift")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.backgroundSecondary)

                        SearchSuggestionsView(
                            onSelect: { text in
                                print("Selected: \(text)")
                            },
                            onClearHistory: {
                                print("Clear history")
                            }
                        )
                        .environment(suggestionsService)
                    }
                    .task {
                        await suggestionsService.getSuggestions(for: "swift")
                    }
                } else {
                    Text("Search suggestions unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Did You Mean") {
    VStack(spacing: 0) {
        DidYouMeanBanner(suggestion: "programming") {
            print("Accepted correction")
        }

        Spacer()
    }
}
