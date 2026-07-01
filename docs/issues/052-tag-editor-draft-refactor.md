# Issue 052: Tag Editor Draft Refactor

Status: closed

## Context

`TagEditorSheet.save()` still owned deterministic tag editor save behaviour:

- trimming whitespace from the entered name.
- lowercasing the tag name.
- checking whether the form can be saved.
- creating a new `Tag`.
- applying edited fields to an existing `Tag`.

The sheet should keep SwiftData insertion/update orchestration, context save, dismissal, and presentation state. The save-field mapping belongs in a focused draft module.

## Acceptance Criteria

- Characterize tag editor draft behaviour before changing `TagEditorSheet`.
- Preserve name normalization:
  - trim leading/trailing whitespace.
  - lowercase the name.
- Preserve disabled-save behaviour for blank names.
- Preserve new tag creation using normalized name and selected color.
- Preserve editing an existing tag using normalized name and selected color.
- Keep model insertion, model-context save, dismissal, and sheet presentation in `TagEditorSheet`.
- Keep `TagsView.swift` below 500 LOC.
- Run focused tag editor draft tests.
- Run nearby tag/model tests and simulator build when Xcode/CoreSimulator is available.

## Implementation

- Added `BookQuotes/Features/Tags/TagEditorDraft.swift`.
- Added `BookQuotesTests/Unit/Models/TagEditorDraftTests.swift`.
- Updated `TagEditorSheet.save()` and save-button disabled state to use `TagEditorDraft`.

## LOC Impact

- `BookQuotes/Features/Tags/TagsView.swift`: 441 LOC.
- `BookQuotes/Features/Tags/TagEditorDraft.swift`: 21 LOC.
- `BookQuotesTests/Unit/Models/TagEditorDraftTests.swift`: 38 LOC.

## Verification

- Focused Tags characterization gate on 2026-07-01:
  - 48 tests executed.
  - 0 failures.
  - Included `TagEditorDraftTests`, nearby tag seams, `TagModelTests`, and `QuoteModelTests`.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Tags UI automation remains tracked separately by issue 081.

## Follow-Up

- Future tag editor save-field changes should start in `TagEditorDraftTests`.
- Issue 060 moved tag editor mode copy and sheet UI out of `TagsView`; future create/edit title or action copy should start in `TagEditorModePresentationTests`.
