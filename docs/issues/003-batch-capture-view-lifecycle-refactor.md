# Batch Capture View Lifecycle Refactor

Status: `closed`

Priority: high

## Problem

`BatchCaptureView.swift` is 754 LOC with a complexity proxy of 58. It owns camera setup, capture state, image preprocessing handoff, thumbnail/detail presentation, offline queue confirmation, draft saving, cancellation, and milestone UI.

The module is performance-sensitive and feeds into extraction review, so it should follow the extraction-review slice.

## Acceptance Criteria

- [x] Current batch capture behaviours are characterized before production edits.
- [x] Tests or simulator acceptance cover capture, thumbnail/detail, remove capture, finish/process confirmation, queue-for-later decision state, save draft, and cancel paths touched by the slice.
- [x] Heavy image/preprocessing and queueing behaviour remains off the main actor where currently required.
- [x] Extracted modules improve locality for capture lifecycle and offline confirmation/detail presentation.
- [x] `BatchCaptureView.swift` moves materially toward sub-500 LOC.
- [x] Verification docs record tests, LOC delta, simulator status, and performance-sensitive assumptions.

## Initial Target

Separate capture lifecycle decisions from thumbnail/detail/offline-confirmation presentation once behaviour is characterized.

## Outcome

Completed on 2026-06-06.

Extracted:

- `BookQuotes/Features/QuoteCapture/BatchCaptureLifecycleState.swift`
- `BookQuotes/Features/QuoteCapture/BatchCaptureSupplementaryViews.swift`

Added:

- `BookQuotesTests/Unit/QuoteCapture/BatchCaptureLifecycleStateTests.swift`
- `BookQuotesUITests/Flows/BatchCaptureFlowTests.testBatchCapture_ThumbnailDetail_CanRemoveCapture`

`BatchCaptureView.swift` moved from 754 LOC to 400 LOC. Verification is recorded in `docs/refactor-foundation/verification/2026-06-06-batch-capture-lifecycle-refactor.md`.
