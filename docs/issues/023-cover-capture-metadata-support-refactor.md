# Cover Capture Metadata Support Refactor

Status: `closed`

Priority: medium

## Problem

`CoverCaptureView.swift` was 486 LOC and still mixed camera/crop UI coordination with cover metadata support behaviours:

- Gemini-first cover metadata extraction orchestration;
- Vision OCR fallback for cover title/author guesses;
- image orientation normalization;
- Vision rectangle detection support;
- ISBN lookup helper.

That made the cover capture screen harder to change safely before further camera framing and cover extraction work.

## Acceptance Criteria

- [x] Characterize cover crop lifecycle, extraction orchestration, and OCR heuristics before production edits.
- [x] Attempt focused mocked-camera simulator UI smoke before production edits.
- [x] Keep `CoverCaptureView` responsible for camera setup, mode switching, crop review presentation, sheet/error state, and user actions.
- [x] Move metadata extraction, OCR fallback, orientation normalization, rectangle detection support, and ISBN lookup behind a support type.
- [x] Preserve Gemini-first extraction and OCR fallback semantics.
- [x] Preserve the manual-entry fallback when cover metadata title is blank.
- [x] Preserve crop-accept flow from review dismissal into processing.
- [x] Move `CoverCaptureView.swift` materially below 500 LOC.
- [x] Build passes after extraction.
- [x] Focused cover crop/extraction/OCR unit tests pass after extraction.
- [x] Focused mocked-camera UI smoke is rerun after extraction.
- [x] Architecture and verification docs record module ownership, test commands, LOC delta, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/BookRegistration/CoverCaptureMetadataSupport.swift`.
- Moved cover metadata extraction, OCR fallback, image normalization, Vision rectangle detection support, and ISBN lookup helpers into the support module.
- Kept `CoverCaptureView` as the camera and sheet-flow coordinator.

## LOC Result

- `CoverCaptureView.swift`: 486 LOC -> 333 LOC.
- `CoverCaptureMetadataSupport.swift`: 164 LOC.

## Residual Risk / Next Slice

- Existing Vision Sendable warnings remain in the extracted support module.
- The focused mocked-camera UI smoke failed during baseline bootstrap but passed after extraction; that gives a useful post-refactor smoke but not a clean before/after UI comparison.
- A follow-on cover capture slice should characterize camera framing and visible first-open camera composition before changing user-facing capture guidance.
