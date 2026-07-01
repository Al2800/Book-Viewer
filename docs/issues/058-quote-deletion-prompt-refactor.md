# Issue 058: Quote Deletion Prompt Refactor

Status: `closed`

## Context

`QuoteDetailView.swift` is below the 500 LOC target but remains one of the larger Library feature screens. Previous slices moved quote detail share/copy text, edit-save mutation, and edit-load field mapping into tested seams.

The remaining quote deletion dialog copy was still embedded directly in the SwiftUI confirmation dialog.

## Acceptance Criteria

- Characterize quote deletion prompt copy before changing `QuoteDetailView`.
- Keep `QuoteDetailView.swift` below 500 LOC.
- Move only stable prompt copy into a value module.
- Keep actual quote deletion, model-context save, haptics, dismissal, and dialog state in `QuoteDetailView`.
- Register the new test and production file in the Xcode project.
- Update architecture and verification docs.
- Attempt focused tests and simulator smoke, recording any local Xcode/CoreSimulator blocker.

## Implementation

- Added `BookQuotes/Features/Library/QuoteDeletionPrompt.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDeletionPromptTests.swift`.
- Updated `QuoteDetailView` to use `QuoteDeletionPrompt` for the confirmation title, destructive action title, and message.

## LOC Impact

- `BookQuotes/Features/Library/QuoteDetailView.swift`: 439 LOC.
- `BookQuotes/Features/Library/QuoteDeletionPrompt.swift`: 5 LOC.
- `BookQuotesTests/Unit/Library/QuoteDeletionPromptTests.swift`: 13 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused Library/Quote Detail characterization gate on 2026-07-01:
    - 78 tests executed.
    - 0 failures.
    - Included `QuoteDeletionPromptTests`, nearby Library seams, and Book/Quote model tests.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Quote Detail UI automation remains tracked separately by issue 081.

## Follow-Up

- Further quote deletion behaviour should stay in `QuoteDetailView` until a broader deletion-action seam is characterized.
- Future quote deletion prompt wording should start in `QuoteDeletionPromptTests`.
