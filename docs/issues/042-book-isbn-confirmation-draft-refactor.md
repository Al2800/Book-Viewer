# Issue 042: Book ISBN Confirmation Draft Refactor

Status: closed

## Problem

`BookISBNConfirmationSheet.swift` was the largest remaining book-registration file and directly constructed `Book` values from edited ISBN metadata. That duplicated save normalization already owned by `BookEditSaveDraft` and made ISBN confirmation behavior hard to characterize without launching SwiftUI.

The sheet should keep UI orchestration, validation triggers, `ModelContext` insertion, cover loading, callbacks, and dismissal. The deterministic mapping from edited ISBN confirmation fields to `Book` should live behind a small tested module.

## Acceptance Criteria

- Characterize ISBN confirmation book creation before production edits.
- Preserve title and author trimming.
- Preserve blank subtitle becoming `nil`.
- Preserve edited publisher trimming.
- Preserve best ISBN from lookup metadata.
- Preserve published year from lookup metadata.
- Preserve page count, reading status, and loaded cover data.
- Reuse existing book edit save normalization rather than duplicating field assignment.
- Keep `BookISBNConfirmationSheet.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby book registration characterization tests.
- Run simulator build.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Features/BookRegistration/BookISBNConfirmationDraft.swift`.
- Added `BookQuotesTests/Unit/BookRegistration/BookISBNConfirmationDraftTests.swift`.
- Updated `BookISBNConfirmationSheet.confirmAndSave()` to delegate book construction to `BookISBNConfirmationDraft`.
- `BookISBNConfirmationDraft` delegates normalized creation to `BookEditSaveDraft`, keeping one save normalization path for book registration flows.

## LOC Result

- `BookQuotes/Features/BookRegistration/BookISBNConfirmationSheet.swift`: 464 LOC -> 454 LOC.
- `BookQuotes/Features/BookRegistration/BookISBNConfirmationDraft.swift`: 32 LOC.
- `BookQuotesTests/Unit/BookRegistration/BookISBNConfirmationDraftTests.swift`: 41 LOC.

The sheet remains below the 500 LOC target. The new module is intentionally small but earns its seam by removing duplicate `Book` field assignment from SwiftUI and making the ISBN confirmation save behavior directly testable.

## Verification

- Focused red test confirmed missing production module before implementation:
  - `BookQuotesTests/BookISBNConfirmationDraftTests`
- Focused green test passed:
  - `BookQuotesTests/BookISBNConfirmationDraftTests`
- Nearby book registration characterization passed:
  - `BookQuotesTests/BookISBNConfirmationDraftTests`
  - `BookQuotesTests/BookEditSaveDraftTests`
  - `BookQuotesTests/BookEditDraftTests`
  - `BookQuotesTests/CoverMetadataNormalizerTests`
  - `BookQuotesTests/CoverExtractionOrchestratorTests`
  - `BookQuotesTests/CoverCropGeometryTests`
- Simulator build passed.

## Residual Risk / Next Slice

- Issue 074 extracted `BookISBNConfirmationSheet.FromScanResult` metadata lookup behind `BookISBNScanLookup` with focused scan lookup characterization.
- The sheet remains presentation-heavy but below target; further splitting should be driven by behavior, not LOC alone.
