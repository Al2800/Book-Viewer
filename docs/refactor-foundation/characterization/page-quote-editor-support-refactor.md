# Page Quote Editor Support Refactor Characterization

Date: 2026-06-30

Issue: `docs/issues/027-page-quote-editor-support-refactor.md`

## Baseline Behaviour

This slice preserves the extraction-review page quote editor.

Editor behaviours:

- The editor displays the selected page image when the full image can be loaded.
- The editor falls back to the thumbnail, then an image-not-found empty state.
- The quote header displays zero, singular, and plural quote counts correctly.
- The Add button and empty-state add button call the manual quote callback.
- Quote delete removes the matching quote identity, not every quote with the same text.
- The full-screen image viewer supports zoom reset, page-number title, and dismiss.
- The page list sorts captures by `orderIndex`, highlights the selected page, shows status, quote count, and detected page number.

## Characterization Used Before Edits

Focused unit baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/ExtractionReviewProcessorTests
```

Result:

- Passed.
- Runtime: `46.092` seconds.

Quote editor UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Blocked before app assertions.
- XCTest runner error: `The test runner failed to initialize for UI testing. (Underlying Error: Timed out waiting for AX loaded notification)`.

## New Characterization Added

- `PageQuoteEditorListTests.testCountTitleUsesSingularAndPluralQuoteLabels`
- `PageQuoteEditorListTests.testDeletingQuoteRemovesOnlyMatchingIdentity`

## Non-Goals

- No change to quote row editing, edit-sheet save/cancel behavior, margin note editing, or extracted quote conversion.
- No change to page image zoom gestures, thumbnail styling, status badges, page selection, add-manual-quote routing, or haptic behavior.
