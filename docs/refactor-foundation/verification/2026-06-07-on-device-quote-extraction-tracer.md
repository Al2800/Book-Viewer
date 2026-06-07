# On-Device Quote Extraction Tracer

## Scope

Issue: `012-on-device-mark-aware-quote-extraction`

This slice introduces the first on-device quote extraction path for marked pages. It is intended to make build 25 useful for TestFlight review without depending on Cloudflare, Gemini, or subscription state for quote page extraction.

This is not the full issue. It is a controlled tracer bullet for underlined readable text.

## Modules Added

- `OnDeviceQuoteExtractor`: public extraction seam returning the existing `QuoteExtractionResult` shape.
- `VisionPageTextRecognizer`: Apple Vision OCR adapter producing text lines with confidence and pixel bounding boxes.
- `PageMarkDetector`: local colored-mark detector for underline, highlight, and margin-mark regions.
- `QuoteMarkTextSelector`: geometry selector that maps detected marks to nearby OCR text lines.

All new app modules are below 500 LOC.

## Product Behaviour

- `ExtractionReviewView` now uses on-device OCR and mark geometry for quote pages.
- The quote review processing path no longer requires network availability before starting.
- The mock-camera single quote image now contains readable underlined text so simulator UI smoke exercises the on-device path.
- Privacy/legal text now says marked quote pages are extracted on-device, while cover extraction or explicit cloud fallback may still use Gemini.

## Verification

Focused extractor tracer:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testExtractsUnderlinedTextFromSyntheticPageWithoutNetwork
```

Result:

- Passed.

Quote-capture simulator smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes
```

Result:

- Passed.

Focused release gate:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed.
- Runtime: `55.352` seconds.

## Release Readiness

Build 25 can be treated as a TestFlight experiment for this new path. The purpose is to test real user pages and gather evidence for the next characterization fixtures.

Known limitations:

- First slice is tuned for clear colored underline/highlight/margin marks.
- Faint pencil underlines and handwritten margin notes are not fully characterized.
- Batch/capture queue paths still need review for remaining cloud extraction seams.
