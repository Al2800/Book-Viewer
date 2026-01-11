import SwiftUI

// MARK: - SearchSuggestionsView

/// View displaying search suggestions as the user types
struct SearchSuggestionsView: View {

    // MARK: - Environment

    @Environment(SearchSuggestionsService.self) private var suggestionsService

    // MARK: - Callbacks

    let onSelect: (String) -> Void
    let onClearHistory: () -> Void

    // MARK: - Body

    var body: some View {
        if !suggestionsService.suggestions.isEmpty {
            List {
                ForEach(suggestionsService.suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        onSelect(suggestion.text)
                    }
                }

                // Clear history button if showing recent searches
                if hasRecentSuggestions {
                    clearHistoryButton
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Computed Properties

    private var hasRecentSuggestions: Bool {
        suggestionsService.suggestions.contains { $0.isRecent }
    }

    // MARK: - Subviews

    private var clearHistoryButton: some View {
        Button(role: .destructive) {
            onClearHistory()
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Clear Recent Searches")
            }
            .font(.subheadline)
        }
    }
}

// MARK: - SuggestionRow

private struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: suggestion.icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(suggestion.text)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                trailingContent
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconColor: Color {
        switch suggestion {
        case .recent:
            return .secondary
        case .bookTitle:
            return .accent
        case .author:
            return .blue
        case .popularTerm:
            return .secondary
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        switch suggestion {
        case .recent:
            Image(systemName: "arrow.up.left")
                .font(.caption)
                .foregroundStyle(.tertiary)

        case .bookTitle:
            Text("Book")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .author:
            Text("Author")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .popularTerm(_, let count):
            if count > 1 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - DidYouMeanBanner

/// Banner suggesting a corrected search query for likely typos
struct DidYouMeanBanner: View {

    // MARK: - Properties

    let suggestion: String
    let onAccept: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            Text("Did you mean:")
                .foregroundStyle(.secondary)

            Button(action: onAccept) {
                Text(suggestion)
                    .fontWeight(.medium)
                    .foregroundStyle(.accent)
            }
            .buttonStyle(.plain)

            Spacer()

            Image(systemName: "arrow.right.circle")
                .foregroundStyle(.accent)
                .font(.callout)
        }
        .font(.subheadline)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.secondary.opacity(0.1))
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
