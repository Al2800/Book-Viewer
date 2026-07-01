# Book ISBN Confirmation Draft Refactor Characterization

Date: 2026-06-30

## Behaviour Characterized

Confirming an ISBN lookup should create a `Book` using the edited confirmation fields and the lookup metadata:

- title and author are trimmed,
- blank subtitle is omitted,
- publisher is trimmed,
- ISBN comes from `metadata.bestISBN`,
- published year comes from metadata,
- page count and reading status are preserved,
- loaded cover image data is assigned to both thumbnail and full cover data.

## Test Added

- `BookQuotesTests/Unit/BookRegistration/BookISBNConfirmationDraftTests.swift`

The test exercises book creation without launching SwiftUI or inserting into SwiftData.

## Refactor Shape

- `BookISBNConfirmationDraft` adapts ISBN confirmation fields into `BookEditSaveDraft`.
- `BookEditSaveDraft` remains the deep module for normalized `Book` creation.
- `BookISBNConfirmationSheet` keeps UI state, validation, model insertion, callbacks, and dismissal.

## Acceptance Criteria Covered

- Edited ISBN metadata creates the same observable `Book` fields as the previous inline sheet code.
- Save normalization is shared with the existing book edit save module.
- The new seam is tested through a public value interface.
