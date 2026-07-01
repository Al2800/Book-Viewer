# Extraction Review Status Presentation Refactor Characterization

Date: 2026-06-30

Issue: `docs/issues/017-extraction-review-status-presentation-refactor.md`

## Baseline Behaviour

This slice preserves extraction review behaviour while moving status presentation out of `ExtractionReviewView`.

Characterized behaviours:

- Completed page snapshots map extracted quotes into editable review state.
- Replacing quotes for one page preserves other pages.
- Failed pages are treated as extraction failures rather than no-quotes states.
- Completed empty pages are treated as no-quotes states.

Intended UI behaviours for the extracted presentation:

- Processing state shows progress and page completion count.
- No-quotes state offers manual quote entry and close.
- Extraction-failure state shows the primary failure message, manual quote entry, and close.
- No-selection state prompts the user to select a page.

## Characterization Used

Unit characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests
```

Result before edits:

- Passed.
- Runtime: `35.438` seconds.

Attempted simulator UI characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Failed before app assertions.
- XCTest runner error: `Timed out waiting for AX loaded notification`.

The UI runner failure repeated after a simulator shutdown and retry with UI-only tests.

## Extracted Module

- `ExtractionReviewStatusViews.swift`: processing, no-quotes, extraction-failure, no-selection, and shared fallback actions.

## Non-Goals

- No change to extraction processing.
- No change to quote editing state.
- No change to quote saving or milestone celebration.
- No change to dismissal semantics.
- No test edits to make the refactor pass.
