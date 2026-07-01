# Issue 028: Batch Capture Page Store Refactor

Status: closed

## Problem

`BatchCaptureView` still owned camera capture orchestration and the heavy page persistence transaction: visible-preview crop, document auto-crop, image preprocessing, thumbnail creation, disk writes, `PageCapture` creation, session ordering, and SwiftData insertion.

That made the view harder to test and made future capture performance changes riskier.

## Acceptance Criteria

- Characterize batch capture page persistence before production edits.
- Add a focused module that owns captured-page persistence behind a small interface.
- Preserve capture order, pending status, thumbnail generation, quality score storage, and image-file creation.
- Keep `BatchCaptureView` responsible for camera capture, lifecycle state, haptics, milestones, and user callbacks.
- Keep all touched files under 500 LOC.
- Run focused batch capture unit tests and simulator build.

## Result

- Added `BatchCapturePageStore`.
- Added `BatchCapturePageStoreTests`.
- `BatchCaptureView` now delegates page persistence and remains under 500 LOC.
