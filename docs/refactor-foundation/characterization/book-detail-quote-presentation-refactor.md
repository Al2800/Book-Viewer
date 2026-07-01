# Characterization: Book Detail Quote Presentation Refactor

Date: 2026-07-01

## Scope

This slice characterized Book Detail quote-list behavior before moving it out of `BookDetailView`.

## Characterized Behavior

`BookDetailQuotePresentationTests` pins:

- marking filters restrict visible quotes to a selected `MarkingType`.
- date-added sort orders by `captureDate` descending.
- page-number sort treats missing page numbers as `0`.
- marking-type sort orders by `MarkingType.rawValue`.
- favorite sort places favorite quotes before non-favorites.
- unique page count ignores nil page values and duplicate page numbers.
- available marking types are unique and sorted by raw value.

## Refactor Rule

`BookDetailQuotePresentation` owns deterministic quote-list presentation policy.

`BookDetailView` keeps SwiftUI-only and persistence orchestration: screen state, controls, navigation links, sheets, delete confirmation, model-context save, haptics, and empty-state presentation.
