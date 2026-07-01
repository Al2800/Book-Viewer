# Issue 034: Search Results Presentation Refactor

Status: closed

## Problem

`SearchResultsView` was below the 500 LOC target, but it still mixed SwiftUI rendering with presentation policy for:

- book/quote section visibility by scope and count;
- row animation delay staggering;
- result-list animation reset;
- did-you-mean fetch eligibility.

Those decisions are behaviorally important for search and were previously hard to test without the whole SwiftUI/SwiftData view.

## Acceptance Criteria

- Add characterization tests for search result section visibility.
- Add characterization tests for existing row animation delay behavior.
- Add characterization tests for result-count animation reset behavior.
- Add characterization tests for did-you-mean fetch eligibility.
- Extract a focused module with real behavior, not a pass-through wrapper.
- Keep `SearchResultsView.swift` below 500 LOC.
- Preserve existing search row accessibility identifiers and navigation callbacks.
- Run focused and nearby search/library tests.
- Run simulator build.
- Attempt search simulator UI smoke and record result.
- Update issue and architecture docs.

## Result

- Added `BookQuotes/Features/Library/SearchResultsPresentation.swift`.
- Added `BookQuotesTests/Unit/Library/SearchResultsPresentationTests.swift`.
- `SearchResultsView` now delegates section visibility, animation-delay, result-reset, and did-you-mean eligibility policy to `SearchResultsPresentation`.

## LOC Result

- `BookQuotes/Features/Library/SearchResultsView.swift`: 396 LOC -> 365 LOC.
- `BookQuotes/Features/Library/SearchResultsPresentation.swift`: 39 LOC.

## Verification

- Red step confirmed missing `SearchResultsPresentation` before implementation.
- Focused tests passed:
  - `BookQuotesTests/SearchResultsPresentationTests`
- Nearby search/library tests passed:
  - `BookQuotesTests/SearchResultsPresentationTests`
  - `BookQuotesTests/LibrarySearchServicesTests`
  - `BookQuotesTests/SearchResultsTests`
  - `BookQuotesTests/SearchServiceTests`
- Simulator build passed.
- Search UI smoke was attempted but failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- Search UI behavior still needs a clean simulator assertion run once the local AX runner issue is resolved.
- Future `SearchResultsView` work should target SwiftData fetch locality or result row composition only when there is a product-facing change or a stronger characterization seam.
