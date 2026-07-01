# Issue 049: Book Deletion Prompt Refactor

Status: closed

## Context

`LibraryView` and `BookDetailView` both displayed the same destructive book-deletion prompt and repeated the same quote-count pluralization logic inline. This copy is user-facing and shared across the two main Library deletion entry points.

The delete persistence itself should remain in the owning views for now because it uses `ModelContext`, routing/dismissal, haptics, and sheet/dialog state.

## Acceptance Criteria

- Characterize the shared deletion prompt copy before changing the call sites.
- Preserve the dialog title format: `Delete "<book title>"?`.
- Preserve the destructive button title: `Delete Book and All Quotes`.
- Preserve the current message:
  - `1 quote` for singular counts.
  - `0 quotes` and `N quotes` for plural counts.
- Reuse the same prompt seam in both Library browsing deletion and Book Detail deletion.
- Do not change delete persistence, haptics, routing, dismissal, or confirmation-dialog presentation state.
- Keep `LibraryTab.swift` and `BookDetailView.swift` below 500 LOC.
- Run focused prompt tests.
- Run nearby Library detail tests and simulator build when Xcode/CoreSimulator is available.

## Implementation

- Added `BookQuotes/Features/Library/BookDeletionPrompt.swift`.
- Added `BookQuotesTests/Unit/Library/BookDeletionPromptTests.swift`.
- Updated `LibraryView` and `BookDetailView` to use `BookDeletionPrompt`.
- Left actual deletion side effects in the existing views.

## LOC Impact

- `BookQuotes/App/LibraryTab.swift`: 384 LOC.
- `BookQuotes/Features/Library/BookDetailView.swift`: 377 LOC.
- `BookQuotes/Features/Library/BookDeletionPrompt.swift`: 20 LOC.
- `BookQuotesTests/Unit/Library/BookDeletionPromptTests.swift`: 38 LOC.

## Verification

- Focused Library/Quote Detail characterization gate on 2026-07-01:
  - 78 tests executed.
  - 0 failures.
  - Included `BookDeletionPromptTests`, nearby Library seams, and Book/Quote model tests.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest Library UI automation remains tracked separately by issue 081.

## Follow-Up

- Future changes to shared book-deletion copy should start in `BookDeletionPromptTests`.
