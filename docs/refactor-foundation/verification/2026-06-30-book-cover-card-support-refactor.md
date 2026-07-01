# Book Cover Card Support Refactor - 2026-06-30

## Scope

- Extracted shared card/list support from `Features/Library/BookCoverCard.swift` into `Features/Library/BookCoverCardSupport.swift`.
- Kept `BookCoverCard` and `BookListRow` as the caller-facing Library card/list row views.
- Preserved title, author, cover/placeholder rendering, quote badges, reading-status badges, context menu labels/actions, tap callbacks, haptics, and accessibility identifiers.

## LOC Result

- `BookQuotes/Features/Library/BookCoverCard.swift`: 502 LOC -> 304 LOC.
- `BookQuotes/Features/Library/BookCoverCardSupport.swift`: 201 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Focused library UI characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks
```

Result before edits:

- Failed before app assertions.
- XCTest UI runner error: `Timed out waiting for AX loaded notification`.
- Runtime before failure: `102.350` seconds.

Result after refactor:

- Failed before app assertions with the same XCTest UI runner error.
- Runtime before failure: `106.657` seconds.

Notes:

- Xcode emitted existing Swift 6 sendability, availability, and simulator framework copy warnings.
- No tests were edited for this slice.

## Residual Risk

- Visual equivalence still needs confirmation when the simulator UI runner can initialize.
- The extraction is intentionally presentational; it does not add a lower-level snapshot or render test harness for SwiftUI cards.
