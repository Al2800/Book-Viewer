# 007 - TestFlight Build 22 Quote Extraction Empty Results

Status: closed
Area: Quote capture
Priority: high

## Problem

Build 22 on TestFlight signs in successfully but returns no quotes from pages that previously extracted marked passages.

## Characterization

- The app sends quote images through the authenticated Gemini proxy.
- A valid proxy response containing `quotes: []` is currently treated as a completed extraction, so the UI can report success while adding no quotes.
- The current prompt is strict about marked passages but does not tell the model to return best-effort marked text when boundaries are imperfect.

## Acceptance Criteria

- Characterization tests lock the prompt behaviour for marked text with uncertain boundaries.
- The prompt explicitly asks for best-effort marked text with lower confidence instead of an empty quote list when readable marked text exists.
- Empty quote arrays are reserved for pages where no marked/readable text is visible.
- Backend/proxy failures remain distinguishable from valid empty extraction results in logs or UI copy.

## Verification

- Run targeted prompt and Gemini parsing tests.
- Re-test on simulator with a known marked-page fixture once the extraction review route issue is closed.

## Progress

2026-06-06:

- Added prompt characterization coverage for uncertain marked-passage boundaries.
- Updated quote extraction prompt to request best-effort marked text with lower confidence rather than empty quote arrays when readable marked text exists.
- Added `PageCapture.completeExtraction(with:)` as the model interface for accepting extraction results.
- Empty `QuoteExtractionResult` values now throw `ExtractionError.noQuotesFound` instead of silently completing a capture with zero quotes.
- Routed `ExtractionReviewView` and `BatchProcessingService` through the same model interface so quote review and batch processing share the invariant.
- Verified non-empty and empty extraction behavior with `PageCaptureTests`.
- Re-ran prompt characterization tests for best-effort marked text and empty-array guidance.
- Re-ran simulator quote capture route into extraction review and quote editor.

## Verification Results

- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/PageCaptureTests`
  - Passed: 5 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests`
  - Passed: 5 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText`
  - Passed: 2 UI tests.

## Residual Risk

- If the same TestFlight symptom persists with real images, the next diagnostic should compare proxy/model responses against the failing images because this issue now prevents valid empty arrays from masquerading as successful extraction.
