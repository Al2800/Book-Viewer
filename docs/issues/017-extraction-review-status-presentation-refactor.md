# Extraction Review Status Presentation Refactor

Status: `closed`

Priority: high

## Problem

`ExtractionReviewView.swift` had grown back over the 500 LOC target after later extraction pipeline work. The added weight was mostly status presentation for processing, no-quotes, extraction-failure, and no-selection states.

Those states are user-visible but do not need to own quote loading, selected page state, extraction processing, persistence, save confirmation, milestone celebration, or dismissal orchestration.

## Acceptance Criteria

- [x] Current extraction review quote-state behaviour is characterized before production edits.
- [x] Existing extraction review tests remain unchanged for this slice.
- [x] Extracted status views own real presentation behaviour and actions, not one-line wrappers.
- [x] `ExtractionReviewView.swift` moves below 500 LOC.
- [x] Processing, save, selected-page, quote-state, and extraction orchestration remain in `ExtractionReviewView`.
- [x] Build passes after extraction.
- [x] Verification docs record the simulator UI runner issue separately from product behaviour.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/QuoteCapture/ExtractionReviewStatusViews.swift`.
- Moved processing, no-quotes, extraction-failure, and no-selection presentation out of `ExtractionReviewView`.
- Kept haptic, add-manual-quote, close, processing, save, quote loading, and dismissal orchestration in `ExtractionReviewView`.

## LOC Result

- `ExtractionReviewView.swift`: 537 LOC -> 467 LOC.
- `ExtractionReviewStatusViews.swift`: 124 LOC.

## Residual Risk / Next Slice

- UI characterization could not complete because the XCTest UI runner repeatedly failed to initialize accessibility: `Timed out waiting for AX loaded notification`.
- Processing/save orchestration remains in `ExtractionReviewView`; a deeper extraction should be guarded by focused tests for pending pages, successful processing, failure handling, partial save, milestone delay, and dismissal.
