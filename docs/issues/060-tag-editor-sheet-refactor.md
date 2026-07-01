# Issue 060: Tag Editor Sheet Refactor

Status: `closed`

## Context

After issue 059, `TagsView.swift` still embedded the full tag editor sheet UI. Existing seams already covered deterministic save-field mapping in `TagEditorDraft`, but the create/edit mode title and confirmation action copy still lived directly inside the sheet implementation.

The next useful slice is to move the editor sheet out of `TagsView` and characterize its mode presentation copy.

## Acceptance Criteria

- Characterize tag editor mode presentation before changing the sheet.
- Preserve create-mode title: `New Tag`.
- Preserve create-mode confirmation action: `Create`.
- Preserve edit-mode title: `Edit Tag`.
- Preserve edit-mode confirmation action: `Save`.
- Move `TagEditorSheet` out of `TagsView`.
- Keep name/color draft normalization in `TagEditorDraft`.
- Keep SwiftData insertion/update, context save, and dismissal in `TagEditorSheet`.
- Keep `TagsView.swift` below 500 LOC.
- Register the new test and production files in the Xcode project.
- Attempt focused tests and simulator smoke, recording any local Xcode/CoreSimulator blocker.

## Implementation

- Added `BookQuotes/Features/Tags/TagEditorModePresentation.swift`.
- Added `BookQuotes/Features/Tags/TagEditorSheet.swift`.
- Added `BookQuotesTests/Unit/Models/TagEditorModePresentationTests.swift`.
- Moved `TagEditorSheet` out of `TagsView`.
- Updated `TagEditorSheet` navigation title and confirmation action title to use `TagEditorModePresentation`.

## LOC Impact

- `BookQuotes/Features/Tags/TagsView.swift`: 402 LOC -> 299 LOC.
- `BookQuotes/Features/Tags/TagEditorSheet.swift`: 92 LOC.
- `BookQuotes/Features/Tags/TagEditorModePresentation.swift`: 21 LOC.
- `BookQuotesTests/Unit/Models/TagEditorModePresentationTests.swift`: 21 LOC.

## Verification

- Focused Tags characterization gate on 2026-07-01:
  - 48 tests executed.
  - 0 failures.
  - Included `TagEditorModePresentationTests`, `TagEditorDraftTests`, nearby tag seams, `TagModelTests`, and `QuoteModelTests`.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Tags UI automation remains tracked separately by issue 081.

## Follow-Up

- Future tag editor mode title/action copy should start in `TagEditorModePresentationTests`.
- Future tag editor save-field changes should remain in `TagEditorDraftTests`.
