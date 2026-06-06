# Extraction Review Modular Refactor Characterization

Date: 2026-06-06

Issue: `docs/issues/002-extraction-review-view-modular-refactor.md`

## Baseline Behaviour

This slice preserves the existing extraction review behaviour while extracting a testable editable-quote state module:

- completed page captures load stored `ExtractedQuoteData` into editable review quotes;
- extracted quote page number falls back to the capture's detected page number when the quote has no page number;
- quote counts are grouped by page ID for the page list;
- page editor bindings replace only the selected page's quotes and preserve other pages;
- manual quote creation remains on the add-quote sheet;
- save still maps editable quotes to `ExtractedQuote` through `QuoteSaveService`;
- partial save keeps failed quotes for further review;
- processing, retry/failure marking, milestone celebration, dismissal, and save-error handling remain in `ExtractionReviewView`.

## Characterization Added

`ExtractionReviewQuoteStateTests` covers:

- loading completed page snapshots into editable review state;
- detected-page fallback;
- page-level quote counts;
- per-page quote replacement and current append order.

## Extracted Modules

- `ExtractionReviewQuoteState.swift`: editable quote collection, page quote counts, loaded quote mapping, per-page replacement, and partial-save failure filtering.
- `ExtractionReviewSupplementaryViews.swift`: add-manual-quote sheet, save summary view, and previews.

## Simulator Gap

Existing simulator tests were run for extraction review display and quote editing. Both skipped before reaching the review screen because `QuoteCaptureFlowTests` could not open the capture path from seeded library data. This route repair is tracked in `docs/issues/006-extraction-review-simulator-route-repair.md`.
