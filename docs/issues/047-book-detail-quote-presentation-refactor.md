# Issue 047: Book Detail Quote Presentation Refactor

Status: closed

## Context

`BookDetailView.swift` remained below the 500 LOC target, but it still directly owned deterministic quote list behavior:

- filtering quotes by marking type.
- sorting quotes by date added, page number, marking type, or favorite status.
- counting unique quoted pages.
- calculating available marking filters.

This behavior is user-visible and needed a lower-level characterization seam before future Book Detail UI or quote-list work.

## Acceptance Criteria

- Characterize current Book Detail quote filtering and sorting before production edits.
- Preserve current behavior:
  - marking filter limits visible quotes to that marking type.
  - date-added sort shows newest capture first.
  - page-number sort treats missing pages as `0`.
  - marking-type sort uses `MarkingType.rawValue`.
  - favorite sort places favorites before non-favorites.
  - unique page count ignores nil pages and duplicate page numbers.
  - available marking filters are unique and sorted by raw value.
- Keep `BookDetailView.swift` below 500 LOC.
- Keep `BookDetailView` responsible for UI orchestration, sheets, navigation, haptics, persistence, and delete handling.
- Run focused tests, nearby Library/model tests, simulator build, and a Book Detail UI smoke attempt.

## Implementation

- Added `BookDetailQuoteSortOrder`.
- Added `BookDetailQuotePresentation`.
- Updated `BookDetailView` to delegate visible quote selection, unique page count, and marking filter list to `BookDetailQuotePresentation`.

## LOC Impact

- `BookQuotes/Features/Library/BookDetailView.swift`: 394 LOC -> 370 LOC.
- `BookQuotes/Features/Library/BookDetailQuotePresentation.swift`: 44 LOC.
- `BookQuotesTests/Unit/Library/BookDetailQuotePresentationTests.swift`: 106 LOC.

## Verification

- Focused RED confirmed missing presentation module.
- Focused GREEN passed:
  - `BookQuotesTests/BookDetailQuotePresentationTests`
- Nearby Library/model characterization passed:
  - `BookQuotesTests/BookDetailQuotePresentationTests`
  - `BookQuotesTests/LibraryNavigationLookupTests`
  - `BookQuotesTests/QuoteDetailTextFormatterTests`
  - `BookQuotesTests/QuoteDetailEditDraftTests`
  - `BookQuotesTests/LibraryContentModeTests`
  - `BookQuotesTests/SearchResultsPresentationTests`
  - `BookQuotesTests/BookModelTests`
  - `BookQuotesTests/QuoteModelTests`
- Simulator build passed.
- Book Detail UI smoke was attempted and failed before app assertions because the UI runner did not initialize:
  - `Timed out waiting for AX loaded notification`.

## Follow-Up

- Book Detail visual controls and empty-state UI remain in `BookDetailView`.
- Extract those only if product-facing Book Detail UI changes need a stronger presentation seam.
