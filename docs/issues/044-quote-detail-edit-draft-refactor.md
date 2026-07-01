# Issue 044: Quote Detail Edit Draft Refactor

Status: closed

## Problem

`QuoteDetailView.swift` still owned deterministic edit-save mapping inline. Pressing Done directly copied edited text, margin note, page-number text, and modified date onto the `Quote` before saving the model context. That behaviour is user-visible, but it was only testable through the full SwiftUI detail screen.

The view should keep editing state, focus, toolbar actions, sheets, model-context save, haptics, deletion, copy/share, and dismissal. The deterministic edit draft application should live behind a small tested module.

## Acceptance Criteria

- Characterize quote-detail edit-save mapping before production edits.
- Preserve edited quote text assignment.
- Preserve edited margin note assignment.
- Preserve empty margin note becoming `nil`.
- Preserve numeric page text becoming `pageNumber`.
- Preserve invalid page text becoming `nil`.
- Preserve `dateModified` update on save.
- Keep `QuoteDetailView.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby Library/model characterization tests.
- Run simulator build.
- Attempt quote-detail UI smoke and record runner status.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Features/Library/QuoteDetailEditDraft.swift`.
- Added `BookQuotesTests/Unit/Library/QuoteDetailEditDraftTests.swift`.
- Updated `QuoteDetailView.saveEdits()` to delegate deterministic quote mutation to `QuoteDetailEditDraft`.
- Kept `QuoteDetailView` responsible for UI state, `ModelContext.save()`, haptics, editing-mode transition, copy/share/delete, source image sheet, marking picker, and dismissal.

## LOC Result

- `BookQuotes/Features/Library/QuoteDetailView.swift`: 435 LOC -> 437 LOC.
- `BookQuotes/Features/Library/QuoteDetailEditDraft.swift`: 15 LOC.
- `BookQuotesTests/Unit/Library/QuoteDetailEditDraftTests.swift`: 41 LOC.

The view remains below the 500 LOC target. The small LOC increase is accepted because the edit-save contract is now characterized through a stable value seam.

## Verification

- Focused red test confirmed the missing production module before implementation:
  - `BookQuotesTests/QuoteDetailEditDraftTests`
- Focused green tests passed:
  - `BookQuotesTests/QuoteDetailEditDraftTests`
- Nearby Library/model characterization passed:
  - `BookQuotesTests/QuoteDetailEditDraftTests`
  - `BookQuotesTests/QuoteDetailTextFormatterTests`
  - `BookQuotesTests/LibrarySearchServicesTests`
  - `BookQuotesTests/LibraryContentModeTests`
  - `BookQuotesTests/LibraryNavigationLookupTests`
  - `BookQuotesTests/SearchResultsPresentationTests`
  - `BookQuotesTests/QuoteModelTests`
- Simulator build passed.
- Quote-detail UI smoke was attempted and failed before app assertions with XCTest runner initialization error:
  - `The test runner failed to initialize for UI testing. (Underlying Error: Timed out waiting for AX loaded notification)`

## Residual Risk / Next Slice

- Marking picker changes still mutate `quote.markingType` directly through a binding. That preserves current behaviour, including the fact that Cancel does not revert a marking picker change made while editing.
- If product behaviour should make all edit fields transactional, create a new issue to characterize Cancel/Done semantics before changing the marking picker binding.
- Quote-detail visible behaviour still needs a healthy UI test runner to validate the full Library-to-detail route.
