# Extraction Review Processing Refactor

Status: `closed`

Priority: high

## Problem

`ExtractionReviewView.swift` had already been reduced below 500 LOC, but it still owned a deep processing transaction:

- fetching enabled marking definitions,
- starting session processing,
- iterating pending captures,
- loading full-resolution images from disk,
- calling the quote extractor,
- completing or failing each capture,
- recording session success/failure,
- saving SwiftData changes,
- refreshing editable quote state.

That made the review screen harder to reason about before adding more extraction, review, or save behaviour.

## Acceptance Criteria

- [x] Characterize existing extraction-review quote state and session/page state transitions before production edits.
- [x] Add focused processor tests before or alongside the extraction.
- [x] Preserve successful pending-capture processing: extracted quote data is stored, capture completes, session records success, and review state refreshes.
- [x] Preserve failed pending-capture processing: capture fails, session records failure, and review state refreshes.
- [x] Keep `ExtractionReviewView.swift` below 500 LOC.
- [x] Keep the new processing module focused and below 500 LOC.
- [x] App build passes.
- [x] Simulator UI smoke is attempted and any runner limitation is recorded.
- [x] Architecture and verification docs record ownership, LOC delta, tests, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/QuoteCapture/ExtractionReviewProcessor.swift`.
- Added `BookQuotesTests/Unit/QuoteCapture/ExtractionReviewProcessorTests.swift`.
- `ExtractionReviewView` now delegates pending capture processing to `ExtractionReviewProcessor`.
- `ExtractionReviewView` keeps UI state, selection, save flow, alerts/sheets, haptics, milestone handling, dismissal, and quote-state loading.
- `ExtractionReviewProcessor` owns marking prompt loading, pending capture iteration, image decode, extractor calls, capture/session mutation, model saves, and refresh callback.

## LOC Result

- `ExtractionReviewView.swift`: 467 LOC -> 396 LOC.
- `ExtractionReviewProcessor.swift`: 93 LOC.
- `ExtractionReviewProcessorTests.swift`: 144 LOC.

## Residual Risk / Next Slice

- The relevant UI smoke still fails at XCTest runner initialization with `Timed out waiting for AX loaded notification`, before app assertions.
- Save flow remains in `ExtractionReviewView`; a later slice can characterize save success/partial/failure and extract save orchestration if feature work needs that seam.
