# Quote Detail Edit Draft Refactor Characterization

Date: 2026-07-01

## Behaviour Characterized

Saving edits from Quote Detail applies the edited fields to the quote:

- edited text replaces quote text,
- edited margin note replaces margin note,
- empty margin note clears the existing margin note,
- numeric page text becomes the quote page number,
- invalid page text clears the existing page number,
- `dateModified` is updated during save.

## Tests Added

- `BookQuotesTests/Unit/Library/QuoteDetailEditDraftTests.swift`

The tests exercise edit application without launching SwiftUI, focusing text fields, saving SwiftData, invoking haptics, or presenting sheets.

## Refactor Shape

- `QuoteDetailEditDraft` owns deterministic edit-field application to a `Quote`.
- `QuoteDetailView` keeps UI state, toolbar/sheet presentation, model-context save, haptics, and navigation/dismissal.

## Acceptance Criteria Covered

- The same observable quote fields are mutated as the previous inline `saveEdits()` implementation.
- Empty and invalid optional field handling is directly characterized.
- The new seam is small, but it earns locality because future edit-save field changes can be tested without the detail screen.
