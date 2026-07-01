# Batch Capture Page Store Characterization

Date: 2026-06-30

Issue: `docs/issues/028-batch-capture-page-store-refactor.md`

## Baseline Behaviour

- Capture is ignored while a capture is already in progress.
- A captured frame is optionally cropped to the visible preview area.
- Document auto-crop still runs before storage.
- High-quality image preprocessing still produces the saved image data.
- Thumbnail data is created for the captured page.
- The saved image is written below the session capture directory.
- A `PageCapture` is inserted, added to the session, ordered by existing capture count, marked pending, and assigned the current quality score.
- Capture success haptics and milestone checks remain in `BatchCaptureView`.

## Characterization Added

- `BatchCapturePageStoreTests.testAppendCaptureStoresImageThumbnailOrderAndQualityScore`

## Non-Goals

- No change to camera capture, preview framing, haptics, milestones, finish/draft flow, offline queue behavior, or image preprocessing choices.
