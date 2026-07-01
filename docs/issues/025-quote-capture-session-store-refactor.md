# Quote Capture Session Store Refactor

Status: `closed`

Priority: high

## Problem

`QuoteCaptureView.swift` remained the largest Swift file and still mixed user-facing camera/review orchestration with the persistence transaction that turns a confirmed image into a `CaptureSession` and `PageCapture`.

That transaction includes image preprocessing, capture-file storage, thumbnail creation, SwiftData insertion, session/page relationship setup, normal ready-to-process state, and UI-test extraction seeding. Keeping that in the view made the capture path harder to characterize without the simulator UI runner and harder to reuse safely.

## Acceptance Criteria

- [x] Characterize existing session/page model behavior before production edits.
- [x] Add focused tests for confirmed quote image persistence.
- [x] Add focused tests for UI-test extraction seeding behavior.
- [x] Preserve normal confirmed-photo behavior: one session, one page, thumbnail data, stored image file, `readyToProcess` session, and pending page.
- [x] Preserve UI-test seeding behavior: one completed page with the existing seeded quote text, page number `12`, and completed session.
- [x] Keep camera setup, camera preview, quality analysis, review sheet presentation, extraction-review presentation, haptics, and error state in `QuoteCaptureView`.
- [x] Move `QuoteCaptureView.swift` further below 500 LOC.
- [x] Build passes.
- [x] Focused unit characterization passes after refactor.
- [x] Simulator quote-capture smoke is attempted and any runner limitation is documented.
- [x] Architecture and verification docs record module ownership, LOC delta, test commands, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/Capture/QuoteCaptureSessionStore.swift`.
- Added `BookQuotesTests/Unit/Capture/QuoteCaptureSessionStoreTests.swift`.
- `QuoteCaptureView` now delegates confirmed-photo persistence to `QuoteCaptureSessionStore`.
- Existing UI-test seeded extraction data moved behind the same store seam.

## LOC Result

- `QuoteCaptureView.swift`: 469 LOC -> 412 LOC.
- `QuoteCaptureSessionStore.swift`: 86 LOC.
- `QuoteCaptureSessionStoreTests.swift`: 67 LOC.

## Residual Risk / Next Slice

- `QuoteCaptureFlowTests/testImageReview_ShowsQualityIndicator` still cannot be used reliably in this environment because the UI runner failed before app assertions with `Timed out waiting for AX loaded notification`.
- The image preparation path still uses concrete `ImagePreprocessor` and filesystem APIs; this is acceptable for characterization because it verifies the real persistence path, but a future performance slice may introduce a narrower image-file adapter if needed.
- `QuoteCaptureView` still owns camera action flow, captured-image preparation, quality analysis, and sheet/full-screen presentation; these are the next seams if this file needs another reduction.
