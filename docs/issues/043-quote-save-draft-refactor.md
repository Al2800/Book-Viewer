# Issue 043: Quote Save Draft Refactor

Status: closed

## Problem

`QuoteSaveService.swift` is still one of the largest service files and directly mapped `ExtractedQuote` into a persisted `Quote` inside the save transaction. That made quote field mapping difficult to characterize without also exercising SwiftData insertion, model saves, duplicate checks, date mutation, and haptics.

The service should keep orchestration, persistence, duplicate handling, model-context saves, book timestamp updates, and haptic feedback. The deterministic conversion from an extracted quote into a validated `Quote` should live behind a small tested module.

## Acceptance Criteria

- Characterize extracted-quote to `Quote` mapping before production edits.
- Preserve quote text.
- Preserve linked book.
- Preserve marking type.
- Preserve confidence.
- Preserve page number.
- Preserve chapter.
- Preserve margin note.
- Preserve source image data.
- Preserve custom marking definition mapping.
- Preserve `Quote.validate()` enforcement before insert.
- Keep `QuoteSaveService.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby quote extraction/save characterization tests.
- Run simulator build.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Services/QuoteSaveDraft.swift`.
- Added `BookQuotesTests/Unit/Services/QuoteSaveDraftTests.swift`.
- Updated `QuoteSaveService.save(_:to:sourceImage:)` to delegate extracted quote mapping to `QuoteSaveDraft`.
- Kept model insertion, book timestamp mutation, context save, duplicate handling, and haptics in `QuoteSaveService`.

## LOC Result

- `BookQuotes/Services/QuoteSaveService.swift`: 463 LOC -> 452 LOC.
- `BookQuotes/Services/QuoteSaveDraft.swift`: 25 LOC.
- `BookQuotesTests/Unit/Services/QuoteSaveDraftTests.swift`: 34 LOC.

`QuoteSaveService.swift` remains below the 500 LOC target. The new module is small but has a clear behavioural contract: create and validate a `Quote` from extracted quote data without persistence side effects.

## Verification

- Focused red test confirmed the missing production module before implementation:
  - `BookQuotesTests/QuoteSaveDraftTests`
- Focused green test passed:
  - `BookQuotesTests/QuoteSaveDraftTests`
- Nearby quote save/extraction characterization passed:
  - `BookQuotesTests/QuoteSaveDraftTests`
  - `BookQuotesTests/QuoteModelTests`
  - `BookQuotesTests/QuoteExtractionPromptBuilderTests`
  - `BookQuotesTests/GeminiServiceTests`
  - `BookQuotesTests/ExtractionReviewQuoteStateTests`
  - `BookQuotesTests/ExtractionReviewProcessorTests`
  - `BookQuotesTests/PageQuoteEditorListTests`
- Simulator build passed.

## Residual Risk / Next Slice

- `QuoteSaveService.swift` still owns batch save orchestration, duplicate checks, persistence, and haptics. Further extraction should be driven by characterization of those behaviours, not just line count.
- Issue 072 moved `ExtractedQuote`, `BatchSaveResult`, `SaveFailure`, and `QuoteSaveError` into `QuoteSaveTypes` after adding focused result/error characterization.
