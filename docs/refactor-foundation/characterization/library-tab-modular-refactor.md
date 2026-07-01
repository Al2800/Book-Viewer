# Library Tab Modular Refactor Characterization

Date: 2026-06-13

Issue: `docs/issues/015-library-tab-modular-refactor.md`

## Baseline Behaviour

This slice keeps `LibraryView` as the Library tab orchestration shell and moves concrete presentation rows/cards into the Library feature folder.

The baseline user-visible behaviours are:

- The Library tab shows seeded books rather than the empty state when test data is preloaded.
- The hidden UI-test book-count marker reports the seeded book count.
- Tapping a book from the Library navigates to book detail.
- Switching to list view exposes book rows with the existing `library_book_list_row` accessibility identifier.
- Swiping a list row exposes delete and then shows the destructive confirmation dialog.
- Search can return seeded results.
- Tapping a search result navigates to book or quote detail.

## Characterization Used

The characterization used existing user-facing UI tests without changing their assertions:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_DisplaysExpectedBookCount \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_TapBook_NavigatesToDetail \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_DeleteBook_ShowsConfirmation \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Query_ShowsResults \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearchResult_TapFirstCell_NavigatesToDetail
```

Result before edits:

- Passed.
- Runtime: `101.068` seconds.

## Extracted Module

- `LibraryOverviewViews.swift`: empty library state, section card, summary card, summary pill, control row, action row, info row, and shared icon-circle visual helper.

## Non-Goals

- No change to search result ranking, suggestions, or indexing.
- No change to Library navigation destinations.
- No change to book delete semantics.
- No change to add/edit book sheet presentation.
- No change to stored `libraryViewMode`.
