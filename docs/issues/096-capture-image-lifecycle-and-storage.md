# 096 - Define and enforce the captured-page image lifecycle

Status: closed
Area: Capture / Storage / Privacy
Priority: critical (release blocker 2)

## Problem

Full page images remain in Documents after extraction, quote saving, and book deletion. Storage reporting omits them, backup exclusion is not explicit, and Clear Image Cache can delete pending captures and drafts.

## Acceptance Criteria

- [x] Pending, draft, queued, completed, and failed images have explicit retention rules.
- [x] Completed images are deleted when no longer required, including after quote save.
- [x] Deleting a book/session removes owned image files without affecting unrelated work.
- [x] Pending and draft captures are protected from cache clearing.
- [x] Capture files use appropriate data protection and backup-exclusion attributes.
- [x] Storage reporting includes every capture and queue directory.

## Verification

- [x] File-lifecycle unit tests for save, retry, delete, and cache-clear paths.
- [x] Migration/cleanup test for existing orphan files.
- [x] Device storage and backup inspection.

## Progress

2026-07-14:

- Capture and queue writes now use iOS file protection and backup exclusion.
- Successful reviewed saves and successful queue processing remove full page images.
- Book deletion removes owned session/queue records and their image files.
- Cache clearing removes only orphan capture/queue files and reports actual image bytes.
- 22 focused PageCapture/CaptureQueue tests passed.

2026-07-15:

- A focused test ran on a physical iPhone 17 / iOS 26.5.2 and inspected the actual device-volume
  metadata for a newly saved capture. Both the image and its directory used
  `completeUntilFirstUserAuthentication` protection and were excluded from backup; image deletion
  also succeeded (1 test, 0 failures). This closes the remaining device inspection.
