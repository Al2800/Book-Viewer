# Page Quote Editor Support Refactor

Status: `closed`

Priority: medium

## Problem

`PageQuoteEditor.swift` was below the 500 LOC target, but it still bundled three modules in one file:

- selected-page quote editor,
- full-screen page image viewer,
- page thumbnail navigation list and cell presentation.

It also kept small list behavior, such as quote-count wording and delete-by-identity, inline in the SwiftUI view.

## Acceptance Criteria

- [x] Characterize current extraction-review quote/editor behavior before production edits.
- [x] Attempt quote-editor simulator smoke before production edits and record runner result.
- [x] Add a focused unit seam for editor quote-list behavior.
- [x] Preserve quote count title behavior for zero, singular, and plural counts.
- [x] Preserve delete-by-identity behavior when quotes share the same text.
- [x] Preserve full image viewer and page thumbnail navigation presentation.
- [x] Reduce `PageQuoteEditor.swift` materially while keeping all files below 500 LOC.
- [x] Build passes.
- [x] Verification docs record tests, LOC delta, and residual simulator risk.

## Outcome

2026-06-30:

- Added `PageQuoteEditorList` for quote count title and delete-by-identity behavior.
- Added `PageQuoteEditorSupportViews` for `FullImageViewer`, `PageListView`, and `PageThumbnailCell`.
- Added `PageQuoteEditorListTests`.
- `PageQuoteEditor` now owns the selected-page editor layout, image section, quote section, empty state, and callback wiring.

## LOC Result

- `PageQuoteEditor.swift`: 448 LOC -> 218 LOC.
- `PageQuoteEditorList.swift`: 17 LOC.
- `PageQuoteEditorSupportViews.swift`: 229 LOC.
- `PageQuoteEditorListTests.swift`: 35 LOC.

## Residual Risk / Next Slice

- Quote editor UI smoke still fails before app assertions in this environment with `Timed out waiting for AX loaded notification`.
- `QuoteEditRow.swift` still owns inline edit sheet behavior and editable quote conversion. A future slice should characterize save/cancel/empty-text behavior before extracting or changing row editing.
