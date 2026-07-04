import SwiftUI

struct SearchEmptyStateView: View {
    let recentSearches: [String]
    let hasAppeared: Bool
    let onSelectRecentSearch: (String) -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            header
            recentSearchesSection
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.tertiary)
                .symbolEffect(.pulse, options: .repeating)

            Text("Search your library")
                .font(.headline)

            Text("Find quotes and books by title, author, or content")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var recentSearchesSection: some View {
        if !recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Recent Searches")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.xs)

                SearchChipScroller(searches: Array(recentSearches.prefix(5)), showsClock: true) {
                    onSelectRecentSearch($0)
                }
            }
            .padding(.top, Spacing.md)
        }
    }
}

struct SearchNoResultsView: View {
    let searchText: String
    let scope: SearchScope
    let recentSearches: [String]
    let didYouMeanSuggestion: String?
    let isLoadingSuggestion: Bool
    let hasAppeared: Bool
    let reduceMotion: Bool
    let onAcceptDidYouMean: (String) -> Void
    let onSelectRecentSearch: (String) -> Void
    let onSearchAll: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            header
            suggestionStatus
            alternatives
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.95)
        .animation(reduceMotion ? .none : .smoothSpring, value: didYouMeanSuggestion)
        .accessibilityIdentifier(AccessibilityIdentifiers.Search.noResultsView)
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("No results for '\(searchText)'")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var suggestionStatus: some View {
        if let suggestion = didYouMeanSuggestion {
            DidYouMeanBanner(suggestion: suggestion) {
                onAcceptDidYouMean(suggestion)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else if isLoadingSuggestion {
            HStack(spacing: Spacing.xs) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Looking for suggestions...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var alternatives: some View {
        VStack(spacing: Spacing.sm) {
            Text("Try these:")
                .font(.caption)
                .foregroundStyle(.tertiary)

            if scope != .all {
                Button {
                    onSearchAll()
                } label: {
                    Label("Search all", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.secondaryCompact)
            }

            recentSearchAlternatives
        }
    }

    @ViewBuilder
    private var recentSearchAlternatives: some View {
        let matches = recentSearches.filter { !$0.lowercased().contains(searchText.lowercased()) }
        if !matches.isEmpty {
            VStack(spacing: Spacing.sm) {
                Divider()
                    .padding(.vertical, Spacing.xs)

                Text("Or try a recent search")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                SearchChipScroller(searches: Array(matches.prefix(4)), showsClock: false) {
                    onSelectRecentSearch($0)
                }
            }
        }
    }
}

struct SearchErrorStateView: View {
    let error: SearchError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(Color.error)

            Text("Search error")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try again") {
                onRetry()
            }
            .buttonStyle(.secondaryCompact)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SearchChipScroller: View {
    let searches: [String]
    let showsClock: Bool
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(searches, id: \.self) { search in
                    Button {
                        onSelect(search)
                    } label: {
                        SearchChip(text: search, showsClock: showsClock)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SearchChip: View {
    let text: String
    let showsClock: Bool

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if showsClock {
                Image(systemName: "clock")
                    .font(.caption2)
            }

            Text(text)
                .lineLimit(1)
        }
        .font(.subheadline)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.backgroundSecondary)
        .clipShape(Capsule())
    }
}
