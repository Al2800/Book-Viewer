# Extraction Review View Modular Refactor

Status: `closed`

Priority: high

## Problem

`ExtractionReviewView.swift` is 784 LOC with a complexity proxy of 77. It owns extraction loading, selected page state, editable quote state, save confirmation, add quote sheet, discard alert, save errors, existing quote queries, milestone side effects, and persistence.

This is central to the quote workflow and should be the next complexity-heavy target after capture-tab routing is stabilized.

## Acceptance Criteria

- [x] Current extraction-review behaviours are characterized before production edits.
- [x] At least one focused unit seam or simulator acceptance test is added or strengthened before extraction.
- [x] Extracted modules own real behaviour such as processing state, review progression, save decisions, or editable quote mapping.
- [x] `ExtractionReviewView.swift` moves materially toward sub-500 LOC.
- [x] Save, retry, discard, add-quote, selected-page, and review progression behaviour are preserved.
- [x] Simulator acceptance was attempted for the review path; existing UI route skipped before reaching review, tracked in issue 006.
- [x] Verification docs record tests, LOC delta, and neutral behaviour notes.

## Initial Target

Look for a deep module around review state/progression or editable quote mapping before extracting presentation sections.

## Outcome

Closed on 2026-06-06.

- `ExtractionReviewView.swift` reduced from 784 LOC to 492 LOC.
- Added `ExtractionReviewQuoteState` for editable quote loading, page counts, per-page replacement, and partial-save filtering.
- Added `ExtractionReviewSupplementaryViews` for manual-quote sheet, review summary, and previews.
- Added focused characterization tests for loaded quote mapping and per-page replacement order.
- Existing extraction-review simulator tests were run, but both skipped because their helper could not reach the capture/review path. That acceptance-test route is tracked separately in `006-extraction-review-simulator-route-repair.md`.

See:

- `docs/refactor-foundation/characterization/extraction-review-modular-refactor.md`
- `docs/refactor-foundation/verification/2026-06-06-extraction-review-modular-refactor.md`
