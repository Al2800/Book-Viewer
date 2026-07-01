# Extraction Review Processing Refactor Characterization

Date: 2026-06-30

Issue: `docs/issues/026-extraction-review-processing-refactor.md`

## Baseline Behaviour

This slice preserves the extraction-review path after a `CaptureSession` reaches review with pending captures.

Successful pending-capture behaviour:

- The session moves from ready-to-process into processing.
- Each pending `PageCapture` begins processing before extraction.
- Enabled marking definitions are converted into prompt values for the extractor.
- The full page image is loaded from the capture image path.
- A successful extraction stores encoded quote data on the capture.
- The capture moves to completed with extracted count, confidence, and page number metadata.
- The session records a success and completes when no pending captures remain.
- Editable quote state is refreshed after the capture mutation.

Failed pending-capture behaviour:

- Extractor or image-load errors mark the capture failed.
- The failure message is retained on the capture.
- The session records a failure and moves to partial failure when all captures are processed.
- Editable quote state is refreshed after the failure mutation.

## Characterization Used Before Edits

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/CaptureSessionTests \
  -only-testing:BookQuotesTests/PageCaptureTests
```

Result:

- Passed.
- Runtime: `28.579` seconds.

## New Characterization Added

- `ExtractionReviewProcessorTests.testProcessingPendingCaptureStoresQuotesAndRecordsSessionSuccess`
- `ExtractionReviewProcessorTests.testProcessingFailureMarksCaptureFailedAndRecordsSessionFailure`

These tests use real in-memory SwiftData models, a real capture image file, and a fake `QuoteExtracting` adapter at the existing extractor seam.

## Non-Goals

- No change to prompt wording, model selection, OCR/model fallback, mark detection, or quote text correction.
- No change to review UI layout, selected-page behavior, add-manual-quote behavior, save confirmation, save flow, milestone celebration, haptics, or dismissal.
- No change to the capture session/page model state-machine methods.
