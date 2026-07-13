# 087 - Quote extraction pipeline deepening

Status: closed
Area: Quote capture / Extraction
Priority: high

## Problem

Quote capture now uses the right product direction: remote model-assisted extraction first, with local OCR as fallback. The implementation still has duplicated construction of the extraction stack in interactive review and offline queue setup, which makes future model, prompt, fallback, logging, and privacy changes easier to apply unevenly.

The extraction module should become deeper: one small interface for callers, with provider selection, fallback policy, and local/remote adapter assembly behind a single seam.

## Acceptance Criteria

- [x] Interactive extraction review and offline queue processing build their quote extractor through one shared module.
- [x] The shared module keeps the current behaviour: remote model-assisted extraction is attempted first; on-device OCR is fallback when the remote route fails or returns no usable quotes.
- [x] Existing model-assisted, on-device, extraction-review, and offline queue characterization tests remain green.
- [x] The extraction module exposes a small caller interface and does not move provider details into SwiftUI views.
- [x] Verification records focused tests, simulator build, and any remaining real-device/TestFlight risks.

## Characterization Plan

- Confirm current `ModelAssistedQuoteExtractor` fallback behaviour through existing public-interface tests.
- Confirm offline queue still uses the same extractor policy as interactive extraction.
- Add a focused characterization only if the shared module introduces a visible behaviour contract that is not already covered.

## Related Issues

- `012-on-device-mark-aware-quote-extraction.md`
- `013-real-photo-mark-detection-and-quote-windowing.md`
- `086-capture-ship-readiness.md`

## Progress

2026-07-13:

- Added `QuoteExtractionPipeline` as the shared extraction policy module.
- Rewired `ExtractionReviewView` and `CaptureQueueManager.initialize` to use `QuoteExtractionPipeline.live(authService:)`.
- Updated focused extraction and queue tests to characterize the pipeline interface.
- Verified 38 focused app tests with 0 failures.
