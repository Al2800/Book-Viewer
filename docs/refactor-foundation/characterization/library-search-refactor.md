# Library Search Refactor Characterization

Date: 2026-06-14

Issue: `docs/issues/015-library-tab-modular-refactor.md`

## Baseline Behaviour

This slice keeps Library search behaviour intact while extracting presentation and SQLite statement mechanics.

The baseline user-visible behaviours are:

- Empty search state appears before a query is entered.
- A no-results state appears when the query has no matches.
- Search scopes for all/books/quotes remain available.
- Seeded quote and book search results still appear for matching queries.
- Tapping the first search result still navigates to detail.
- `SearchDatabase` still indexes, searches, suggests, counts, and corrects terms through the existing FTS5 SQL.

## Characterization Used

The characterization used existing tests without changing their assertions:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/SearchDatabaseTests \
  -only-testing:BookQuotesTests/FTSQueryCorrectnessIntegrationTests \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_NoResults_ShowsEmptyState \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Scopes_Available \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Query_ShowsResults \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_SeededQuote_ReturnsMatch \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearchResult_TapFirstCell_NavigatesToDetail
```

Result before search edits:

- Passed.
- Runtime: `84.313` seconds.

## Extracted Modules

- `SearchResultsStateViews.swift`: empty search, no-results, error presentation, and search suggestion chips.
- `SQLiteStatement.swift`: SQLite statement preparation, finalization, binding, stepping, and typed column reads.
- `SearchFTSQueryBuilder.swift`: FTS5 query normalization and prefix-query construction.

## Non-Goals

- No change to search ranking.
- No change to FTS table schema.
- No change to search result limits.
- No change to search row presentation.
- No change to Library navigation destinations.
- No change to tests to make the refactor pass.
