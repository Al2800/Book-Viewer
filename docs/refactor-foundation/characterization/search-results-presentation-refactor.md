# Search Results Presentation Refactor Characterization

Date: 2026-06-30

## Scope

This slice characterized presentation policy inside `SearchResultsView` before extracting it:

- section visibility;
- animation-delay staggering;
- result-count animation reset;
- did-you-mean fetch eligibility.

The behavior was extracted without changing search execution, SwiftData row fetches, row accessibility identifiers, or navigation callbacks.

## Red Step

Added `SearchResultsPresentationTests` first.

The focused test run failed because `SearchResultsPresentation` did not exist, confirming the new tests were wired into the test target and were driving the production module.

## Characterized Behavior

- `.all` scope shows both books and quotes when both have results.
- `.books` scope hides quotes even when quote results exist.
- `.quotes` scope hides books even when book results exist.
- Empty result sections are hidden.
- Book row animation delays use `min(index, 8) * 0.04`.
- Quote row animation delays use `min(bookCount + index, 12) * 0.04`.
- Results animation resets when count moves from zero to non-zero.
- Did-you-mean fetch is eligible only when the query is non-empty, the result count is zero, and search is idle.

## Refactor

- Added `SearchResultsPresentation`.
- Updated `SearchResultsView` to ask the presentation policy for section visibility, animation delays, reset eligibility, and did-you-mean eligibility.

## Verification

See `docs/refactor-foundation/verification/2026-06-30-search-results-presentation-refactor.md`.
