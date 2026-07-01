# Issue 037: Library Navigation Lookup Refactor

Status: closed

## Problem

`LibraryView` delegated search execution and top-level content mode, but search result navigation still performed inline SwiftData lookups for selected books and quotes. That kept persistence lookup details inside the SwiftUI view and left an existing characterization test red.

## Acceptance Criteria

- Characterize book lookup by search result identifier before production edits.
- Characterize quote lookup by search result identifier before production edits.
- Preserve missing identifier behavior: return `nil` and do not navigate.
- Replace inline `LibraryView` SwiftData lookup with a small tested module.
- Keep `LibraryTab.swift` below 500 LOC.
- Run focused Library navigation lookup tests.
- Keep this as a behavior-preserving refactor; no search UI behavior changes.

## Result

- Added `BookQuotes/Features/Library/LibraryNavigationLookup.swift`.
- Wired `LibraryView` search-result taps through `LibraryNavigationLookup`.
- Removed inline `fetchBook` and `fetchQuote` methods from `LibraryTab.swift`.

## LOC Result

- `BookQuotes/App/LibraryTab.swift`: 387 LOC -> 375 LOC.
- `BookQuotes/Features/Library/LibraryNavigationLookup.swift`: 22 LOC.

## Verification

- Red state observed: `BookQuotesTests/LibraryNavigationLookupTests` failed because `LibraryNavigationLookup` was missing.
- Focused green test passed:
  - `BookQuotesTests/LibraryNavigationLookupTests`

## Residual Risk / Next Slice

- Library UI smoke remains dependent on the local XCTest accessibility runner being healthy.
- `LibraryView` still owns refresh orchestration and delete/edit sheet state; characterize those before extracting.
