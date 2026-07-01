# Issue 050: Quote Detail Edit Fields Refactor

Status: closed

## Context

`QuoteDetailEditDraft` already owns the deterministic save mapping from edited fields back into a `Quote`, but `QuoteDetailView.startEditing()` still owned the inverse mapping from a live quote into editable field strings.

That kept edit-load behaviour split from edit-save behaviour and made future changes to quote editing more likely to touch SwiftUI state directly.

## Acceptance Criteria

- Characterize quote-to-edit-field loading before changing `QuoteDetailView`.
- Preserve edit mode initialization:
  - quote text loads into the text editor field.
  - existing margin note loads into the margin note field.
  - missing margin note loads as an empty string.
  - existing page number loads as a string.
  - missing page number loads as an empty string.
- Keep edit-save behaviour in `QuoteDetailEditDraft`.
- Keep `QuoteDetailView` responsible for UI state, haptics, animation, focus, model-context save, sheets, and dismissal.
- Keep `QuoteDetailView.swift` below 500 LOC.
- Run focused edit-field tests.
- Run nearby Quote Detail and Library tests plus simulator build when Xcode/CoreSimulator is available.

## Implementation

- Added `BookQuotes/Features/Library/QuoteDetailEditFields.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDetailEditFieldsTests.swift`.
- Updated `QuoteDetailView.startEditing()` to load editable state through `QuoteDetailEditFields`.

## LOC Impact

- `BookQuotes/Features/Library/QuoteDetailView.swift`: 438 LOC.
- `BookQuotes/Features/Library/QuoteDetailEditFields.swift`: 11 LOC.
- `BookQuotesTests/Unit/Library/QuoteDetailEditFieldsTests.swift`: 27 LOC.

## Verification

- Focused Library/Quote Detail characterization gate on 2026-07-01:
  - 78 tests executed.
  - 0 failures.
  - Included `QuoteDetailEditFieldsTests`, nearby Library seams, and Book/Quote model tests.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Quote Detail UI automation remains tracked separately by issue 081.

## Follow-Up

- Future changes to Quote Detail edit-load behaviour should start in `QuoteDetailEditFieldsTests`.
