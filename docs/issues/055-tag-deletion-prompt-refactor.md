# Issue 055: Tag Deletion Prompt Refactor

Status: closed

## Context

`TagsView` still embedded deterministic deletion prompt copy:

- the dialog title.
- the destructive action title.
- singular/plural quote-count warning text.

The view should keep delete dialog state, SwiftData deletion, context save, and selected-tag clearing. The prompt copy belongs in a focused value module so future copy/pluralization changes are characterized without touching SwiftUI orchestration.

## Acceptance Criteria

- Characterize tag deletion prompt copy before changing `TagsView`.
- Preserve title: `Delete Tag?`.
- Preserve destructive action title: `Delete Tag`.
- Preserve singular warning copy for one quote.
- Preserve plural warning copy for multiple quotes.
- Keep model deletion, model-context save, and dialog state in `TagsView`.
- Keep `TagsView.swift` below 500 LOC.
- Run focused tag deletion prompt tests.
- Run nearby tag/model tests and simulator build when Xcode/CoreSimulator is available.

## Implementation

- Added `BookQuotes/Features/Tags/TagDeletionPrompt.swift`.
- Added `BookQuotesTests/Unit/Models/TagDeletionPromptTests.swift`.
- Updated `TagsView` delete confirmation title, destructive action title, and message to use `TagDeletionPrompt`.

## LOC Impact

- `BookQuotes/Features/Tags/TagsView.swift`: 447 LOC.
- `BookQuotes/Features/Tags/TagDeletionPrompt.swift`: 10 LOC.
- `BookQuotesTests/Unit/Models/TagDeletionPromptTests.swift`: 30 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused Tags characterization gate on 2026-07-01:
    - 48 tests executed.
    - 0 failures.
    - Included `TagDeletionPromptTests`, nearby tag seams, `TagModelTests`, and `QuoteModelTests`.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Tags UI automation remains tracked separately by issue 081.

## Follow-Up

- Future tag deletion prompt copy/pluralization changes should start in `TagDeletionPromptTests`.
- If tag deletion grows side effects beyond model-context deletion, characterize a separate deletion action module before extraction.
