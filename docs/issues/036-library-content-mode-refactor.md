# Issue 036: Library Content Mode Refactor

Status: closed

## Problem

`LibraryView` was below the 500 LOC target, but its top-level content decision was still embedded directly in SwiftUI branching:

- show search results when search is active and the search text is non-empty;
- show the empty library state when there are no books;
- otherwise show the normal library browser.

This is a small but visible behaviour seam. It decides whether search, empty-state, or browsing UI appears, and it should be easy to characterize before future Library features change search or empty-state behaviour.

## Acceptance Criteria

- Characterize Library content-mode selection before production edits.
- Preserve active non-empty search taking precedence over empty library state.
- Preserve active empty search falling back to empty library when there are no books.
- Preserve inactive search showing the library when books exist, even if search text remains in state.
- Preserve inactive search showing empty library when no books exist.
- Keep `LibraryTab.swift` below 500 LOC.
- Add focused tests for the extracted module.
- Run nearby Library/Search characterization tests.
- Run simulator build.
- Attempt Library simulator UI smoke and record runner result.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Features/Library/LibraryContentMode.swift`.
- Added `BookQuotesTests/Unit/Library/LibraryContentModeTests.swift`.
- `LibraryView` now delegates top-level search/empty/library content selection to `LibraryContentMode`.

## LOC Result

- `BookQuotes/App/LibraryTab.swift`: 386 LOC -> 387 LOC.
- `BookQuotes/Features/Library/LibraryContentMode.swift`: 19 LOC.

The view remains below the 500 LOC target. The one-line increase is accepted because the top-level branch now names the three content modes explicitly while the decision rules live in a focused tested module.

## Verification

- Focused red test confirmed missing production module before implementation.
- Focused green tests passed:
  - `BookQuotesTests/LibraryContentModeTests`
- Nearby Library/Search characterization passed:
  - `BookQuotesTests/LibraryContentModeTests`
  - `BookQuotesTests/LibrarySearchServicesTests`
  - `BookQuotesTests/SearchResultsPresentationTests`
  - `BookQuotesTests/QuoteDetailTextFormatterTests`
  - `BookQuotesTests/SearchResultsTests`
  - `BookQuotesTests/SearchServiceTests`
- Simulator build passed.
- Library UI smoke attempted but failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- Library UI behavior still needs a clean simulator assertion run once the local AX runner issue is resolved.
- `LibraryView` still owns refresh orchestration and delete confirmation state. Future slices should characterize those seams before extraction.
