# 097 - Prevent duplicate offline extraction and make drafts resumable

Status: in_progress
Area: Capture Queue / Drafts / UX
Priority: critical (release blocker 3)

## Problem

Offline batch capture records the same page in the interactive session and retry queue. Interactive review can save local fallback results while the queue later inserts model results directly, bypassing review and duplicate detection. Save Draft has no discoverable resume route, and the UI promises notifications that are not implemented.

## Acceptance Criteria

- [x] Each newly captured page has one authoritative processing lifecycle.
- [x] New offline captures cannot be auto-inserted by the legacy queue.
- [x] Reprocessing is idempotent and duplicate-safe for legacy queue records.
- [x] Saved drafts are listed, resumable, and deletable.
- [x] Offline processing preserves captured work through on-device fallback.
- [x] Unsupported queue-notification copy is no longer reachable for new captures.

## Verification

- Offline-to-online integration tests with duplicate assertions.
- UI tests for save, resume, discard, retry, and review.
- Device test with network loss during a multi-page session.

## Progress

2026-07-14:

- `Process` now always opens Extraction Review; offline requests use the existing on-device fallback instead of creating a second queue copy.
- `Save Draft` now surfaces a Saved Drafts section with resume and delete actions.
- Focused process and save/resume UI tests pass on iPhone 17 / iOS 26.5.
- Legacy queue records now reuse existing similar quotes, suppress repeated extractor output, and
  preserve their resolved-quote relationship so a completed item never calls the extractor again.
- Queue startup returns interrupted `processing` records to `pending`; the duplicate-safe processor
  makes that recovery safe after termination or network loss.
- 32 queue, offline-flow, and extraction-review tests passed on iPhone 17 / iOS 26.5 with no
  failures or skips. A physical-device network-loss run during a multi-page session remains a
  manual release verification step.
