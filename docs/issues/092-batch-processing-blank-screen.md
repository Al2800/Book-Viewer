# 092 - Batch processing presents a blank review screen

Status: closed
Area: Batch Capture / Extraction Review
Priority: critical (release blocker 1)

## Problem

After capturing a page and choosing `Process 1 Pages`, the app can present an empty white full-screen cover instead of Extraction Review. `BatchCaptureFlowView` sets an optional session and a separate presentation Boolean in the same update, so the cover can be created before its required session is available.

## Evidence

- Reproduced twice on the iPhone 17 / iOS 26.5 simulator.
- `BatchCaptureFlowTests.testBatchCapture_ProcessOption_ProcessesCaptures` fails at the review/navigation assertion.
- Failure screenshot contains only the status bar and an otherwise blank white view.

## Acceptance Criteria

- [x] Presentation is driven by the captured session value, with no empty presentation state.
- [x] Processing one or more captured pages always opens Extraction Review.
- [x] Completing review invokes the original completion callback exactly once.
- [x] A regression test fails on the old implementation and passes on the fix.

## Verification

- Focused unit tests for the presentation state.
- Focused batch-capture UI test on an iPhone simulator.
- Manual multi-page smoke test.

## Resolution

`BatchCaptureFlowView` now uses `fullScreenCover(item:)` with the captured session as the presentation source of truth. The focused UI regression test passed on iPhone 17 / iOS 26.5; result bundle: `Test-BookQuotes-2026.07.14_14-20-27-+0100.xcresult`.
