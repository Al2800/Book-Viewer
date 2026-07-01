# Issue 072: Quote Save Result Types Refactor

Status: `closed`

## Context

`QuoteSaveService.swift` was still one of the larger core extraction-adjacent service files at 452 LOC. Previous work moved deterministic quote construction into `QuoteSaveDraft`, but the service file still owned input/result/error value contracts that are used by extraction review and save flows:

- `ExtractedQuote`
- `BatchSaveResult`
- `SaveFailure`
- `QuoteSaveError`

Those types do not perform persistence, duplicate detection, model-context saves, or haptics. Keeping them inside `QuoteSaveService.swift` made the service file harder to scan and left result-summary behaviour without direct characterization.

## Acceptance Criteria

- [x] Characterize `BatchSaveResult` full-success, partial-success, and full-failure behaviour.
- [x] Characterize `SaveFailure.errorMessage` for validation errors.
- [x] Characterize `QuoteSaveError` user-facing descriptions.
- [x] Move quote-save input/result/error value contracts out of `QuoteSaveService.swift`.
- [x] Keep `QuoteSaveService` responsible for persistence, duplicate checks, book timestamp mutation, context saves, and haptics.
- [x] Keep all touched production files below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused quote-save tests when the local Xcode runner is healthy.
- [x] Run simulator smoke for the adjacent seeded/mock-camera and subscription media release routes.

## Implementation

- Added `BookQuotes/Services/QuoteSaveTypes.swift`.
- Added `BookQuotesTests/Unit/Services/QuoteSaveResultTests.swift`.
- Moved `ExtractedQuote`, `BatchSaveResult`, `SaveFailure`, and `QuoteSaveError` from `QuoteSaveService.swift` into `QuoteSaveTypes.swift`.
- Left `QuoteSaveService` orchestration unchanged.

## Verification

- `git diff --check` passed.
- `plutil -lint BookQuotes.xcodeproj/project.pbxproj` passed.
- Duplicate type scan found one source for each moved quote-save type.
- LOC check:
  - `BookQuotes/Services/QuoteSaveService.swift`: 307 LOC.
  - `BookQuotes/Services/QuoteSaveTypes.swift`: 114 LOC.
  - `BookQuotesTests/Unit/Services/QuoteSaveResultTests.swift`: 98 LOC.
- Focused book/save/subscription gate passed: 21 tests, 0 failures.
- Broad unit gate passed: 548 tests, 0 failures.
- Seeded/mock-camera launch smoke passed with 3 books and 6 quotes visible.
- Subscription media route smoke passed with monthly/yearly plans and `Start Free Trial` visible.

See `docs/refactor-foundation/verification/2026-07-01-book-save-subscription-reconciliation.md`.

## Follow-Up

- Further `QuoteSaveService` extraction should start with batch-save orchestration or duplicate-check characterization, not with line count alone.
