# Issue 059: Tag Row Presentation Refactor

Status: `closed`

## Context

`TagsView.swift` remained one of the larger feature files and still contained the concrete tag row menu/chip implementation inline.

Existing tag seams already cover browsing calculations, editor draft normalization, add-to-quote availability, quote/tag mutation, and deletion prompt copy. The next useful slice is to move row display behaviour out of `TagsView` without moving tag creation, editing, deletion, or SwiftData save orchestration.

## Acceptance Criteria

- Characterize tag row display values before changing `TagsView`.
- Preserve displayed tag name.
- Preserve displayed quote-count text.
- Preserve configured color lookup through `CollectionColor`.
- Preserve fallback to blue for unknown tag color names.
- Move row menu/chip presentation out of `TagsView`.
- Keep tag edit/delete action callbacks owned by the caller.
- Keep `TagsView.swift` below 500 LOC.
- Register the new test and production files in the Xcode project.
- Attempt focused tests and simulator smoke, recording any local Xcode/CoreSimulator blocker.

## Implementation

- Added `BookQuotes/Features/Tags/TagRowPresentation.swift`.
- Added `BookQuotes/Features/Tags/TagRowViews.swift`.
- Added `BookQuotesTests/Unit/Models/TagRowPresentationTests.swift`.
- Moved `TagRow` out of `TagsView`.
- Updated `TagRow` to use `TagRowPresentation` for name, quote-count text, and color lookup.

## LOC Impact

- `BookQuotes/Features/Tags/TagsView.swift`: 447 LOC -> 402 LOC.
- `BookQuotes/Features/Tags/TagRowPresentation.swift`: 15 LOC.
- `BookQuotes/Features/Tags/TagRowViews.swift`: 47 LOC.
- `BookQuotesTests/Unit/Models/TagRowPresentationTests.swift`: 34 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused Tags characterization gate on 2026-07-01:
    - 48 tests executed.
    - 0 failures.
    - Included `TagRowPresentationTests`, nearby tag seams, `TagModelTests`, and `QuoteModelTests`.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Tags UI automation remains tracked separately by issue 081.

## Follow-Up

- Future tag row display changes should start in `TagRowPresentationTests`.
- If tag row actions gain side effects beyond callback routing, characterize an action module before extraction.
