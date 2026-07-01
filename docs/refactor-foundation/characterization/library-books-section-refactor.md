# Library Books Section Characterization

Date: 2026-06-30

Issue: `docs/issues/015-library-tab-modular-refactor.md`

## Baseline Behaviour

This slice keeps Library browsing behaviour intact while extracting the Books section presentation from `LibraryTab.swift`.

Behaviours retained:

- The Library tab still owns SwiftData `Book` query state.
- The Library tab still owns search service setup, search text, search scope, and suggestion updates.
- The Library tab still owns add/edit/delete sheet state and delete confirmation.
- The Books section still switches between grid and list presentation using the persisted `libraryViewMode`.
- Grid book cards keep `AccessibilityIdentifiers.Library.bookCoverCard`.
- List rows keep `AccessibilityIdentifiers.Library.bookListRow`.
- The view-mode segmented control keeps `AccessibilityIdentifiers.Library.viewModeToggle`.
- Tap, edit, and delete callbacks still route back through `LibraryView`.
- Book entrance animations still respect reduced motion and stagger by visible index.

## Characterization Used

Focused Library UI baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_DisplaysExpectedBookCount
```

Result before edits:

- Failed before app assertions.
- Failure: `BookQuotesUITests-Runner ... Timed out waiting for AX loaded notification`.

## Extracted Module

- `LibraryBooksSectionViews.swift`: Books section, grid/list rendering, and Library view-mode segmented control.

## Non-Goals

- No change to search results, search service setup, suggestions, add/edit/delete sheets, refresh, routing, or SwiftData persistence.
- No change to tests to make this pass.
