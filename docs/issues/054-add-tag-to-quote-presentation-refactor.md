# Issue 054: Add Tag To Quote Presentation Refactor

Status: closed

## Context

`AddTagToQuoteSheet` still embedded one deterministic quote-tag presentation rule:

- tags already attached to the quote should not be offered in the available-tags section.
- remaining available tags should preserve the sorted `allTags` order supplied by SwiftData.

The sheet should keep current-tag presentation, create-tag sheet routing, relationship mutation calls, model-context saves, and dismissal. The available-tag filtering belongs in a focused presentation module.

## Acceptance Criteria

- Characterize available-tag filtering before changing `AddTagToQuoteSheet`.
- Preserve exclusion of tags already attached to the quote.
- Preserve the order of `allTags` for tags still available to add.
- Preserve behavior when the quote has no current tags: all tags remain available.
- Keep quote/tag relationship mutation in `QuoteTagMutation`.
- Keep create-tag sheet routing, model-context save, and dismissal in `AddTagToQuoteSheet`.
- Keep `TagsView.swift` below 500 LOC.
- Run focused add-tag presentation tests.
- Run nearby tag/model tests and simulator build when Xcode/CoreSimulator is available.

## Implementation

- Added `BookQuotes/Features/Tags/AddTagToQuotePresentation.swift`.
- Added `BookQuotesTests/Unit/Models/AddTagToQuotePresentationTests.swift`.
- Updated `AddTagToQuoteSheet.availableTags` to delegate to `AddTagToQuotePresentation`.

## LOC Impact

- `BookQuotes/Features/Tags/TagsView.swift`: 443 LOC.
- `BookQuotes/Features/Tags/AddTagToQuotePresentation.swift`: 9 LOC.
- `BookQuotesTests/Unit/Models/AddTagToQuotePresentationTests.swift`: 30 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused Tags characterization gate on 2026-07-01:
    - 48 tests executed.
    - 0 failures.
    - Included `AddTagToQuotePresentationTests`, nearby tag seams, `TagModelTests`, and `QuoteModelTests`.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Add Tag UI automation remains tracked separately by issue 081.

## Follow-Up

- Future add-to-quote availability changes should start in `AddTagToQuotePresentationTests`.
- If add-to-quote starts owning more selection state, characterize that behavior separately before extracting another module.
