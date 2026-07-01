# Issue 051: Tags Presentation Refactor

Status: closed

## Context

Issue 045 left `TagsView` with two deterministic presentation calculations still embedded in SwiftUI:

- total tag usage count.
- search filtering for visible tags.

`TagsView` is below the 500 LOC target, so this slice is about locality and characterization rather than reducing file size. Future tag browsing changes should alter a small presentation seam before editing the view.

## Acceptance Criteria

- Characterize tag presentation calculations before changing `TagsView`.
- Preserve total-use calculation as the sum of every tag's `quoteCount`.
- Preserve empty-search behaviour: all tags are visible.
- Preserve case-insensitive search filtering by tag name.
- Keep tag creation, editing, deletion, quote/tag relationship mutation, SwiftData saves, and sheet state in the existing views.
- Keep `TagsView.swift` below 500 LOC.
- Run focused tags presentation tests.
- Run nearby tag/model tests and simulator build when Xcode/CoreSimulator is available.

## Implementation

- Added `BookQuotes/Features/Tags/TagsPresentation.swift`.
- Added `BookQuotesTests/Unit/Models/TagsPresentationTests.swift`.
- Updated `TagsView.filteredTags` and `TagsView.totalUses` to delegate to `TagsPresentation`.

## LOC Impact

- `BookQuotes/Features/Tags/TagsView.swift`: 441 LOC.
- `BookQuotes/Features/Tags/TagsPresentation.swift`: 15 LOC.
- `BookQuotesTests/Unit/Models/TagsPresentationTests.swift`: 45 LOC.

## Verification

- Focused Tags characterization gate on 2026-07-01:
  - 48 tests executed.
  - 0 failures.
  - Included `TagsPresentationTests`, nearby tag seams, `TagModelTests`, and `QuoteModelTests`.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Tags UI automation remains tracked separately by issue 081.

## Follow-Up

- Future tag browsing calculation changes should start in `TagsPresentationTests`.
- Issue 059 moved tag row display values and menu/chip presentation out of `TagsView`; future row display changes should start in `TagRowPresentationTests`.
