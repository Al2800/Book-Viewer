# Issue 074: Book ISBN Scan Lookup Refactor

Status: `closed`

## Context

`BookISBNConfirmationSheet.swift` remained the largest SwiftUI file at 458 LOC, and previous ISBN confirmation issues left one explicit follow-up: `BookISBNConfirmationSheet.FromScanResult` directly created `ISBNLookupService()` for scan-result metadata loading.

The scan-result route has two separable concerns:

- perform an async ISBN metadata lookup and return success/failure;
- present loading, found metadata, and error states in SwiftUI.

The metadata lookup should be characterizable without launching the sheet or using live ISBN network services.

## Acceptance Criteria

- [x] Characterize successful scan-result metadata lookup with a fake lookup.
- [x] Characterize failed scan-result metadata lookup with a fake error.
- [x] Move scan-result metadata lookup behind an injectable seam.
- [x] Preserve the existing `BookISBNConfirmationSheet.FromScanResult` caller-facing API.
- [x] Move scan-result loading/error presentation out of `BookISBNConfirmationSheet.swift`.
- [x] Keep all touched production files below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused ISBN confirmation tests when the local Xcode runner is healthy.
- [x] Run simulator smoke for the adjacent seeded/mock-camera and subscription media release routes.

## Implementation

- Added `BookQuotes/Features/BookRegistration/BookISBNScanLookup.swift`.
- Added `BookQuotes/Features/BookRegistration/BookISBNScanResultView.swift`.
- Added `BookQuotesTests/Unit/BookRegistration/BookISBNScanLookupTests.swift`.
- Introduced `BookISBNMetadataLookup` and made `ISBNLookupService` conform.
- Updated `BookISBNConfirmationSheet.FromScanResult` to use injectable `BookISBNScanLookup`.
- Moved the `FromScanResult` nested view extension into its own file while preserving the nested type name.

## Verification

- `git diff --check` passed.
- `plutil -lint BookQuotes.xcodeproj/project.pbxproj` passed.
- LOC check:
  - `BookQuotes/Features/BookRegistration/BookISBNConfirmationSheet.swift`: 363 LOC.
  - `BookQuotes/Features/BookRegistration/BookISBNScanLookup.swift`: 34 LOC.
  - `BookQuotes/Features/BookRegistration/BookISBNScanResultView.swift`: 107 LOC.
  - `BookQuotesTests/Unit/BookRegistration/BookISBNScanLookupTests.swift`: 40 LOC.
- Focused book/save/subscription gate passed: 21 tests, 0 failures.
- Broad unit gate passed: 548 tests, 0 failures.
- Seeded/mock-camera launch smoke passed with 3 books and 6 quotes visible.

See `docs/refactor-foundation/verification/2026-07-01-book-save-subscription-reconciliation.md`.

## Follow-Up

- Cover-image loading in `BookISBNConfirmationSheet` still creates `ISBNLookupService()` directly. Extract that only when characterizing cover image load success/failure behavior.
