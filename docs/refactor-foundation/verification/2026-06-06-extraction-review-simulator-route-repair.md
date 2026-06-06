# Extraction Review Simulator Route Repair

Date: 2026-06-06
Issue: `006-extraction-review-simulator-route-repair.md`

## Baseline

Command:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Both selected tests skipped with `Capture button not available`.
- Route failure: helper could not find `library_book_list_row`, tapped generic Library fallback controls, then drifted into the add-book path while looking for capture controls.

## Change

- Repaired extraction-review helper path to use Capture tab -> Quote mode -> seeded book selection.
- Removed the fragile dependency on Library list row selection for extraction-review UI tests.
- Kept production code unchanged.

## Verification

Command:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed: `testExtractionReview_DisplaysExtractedQuotes`
- Passed: `testQuoteEditor_CanEditText`
- Executed 2 UI tests with 0 failures and 0 skips.

## Notes

- The repaired route uses seeded data and mock camera.
- This unlocks simulator acceptance coverage for issue 007.
