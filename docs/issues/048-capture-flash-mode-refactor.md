# Issue 048: Capture Flash Mode Refactor

Status: closed

## Context

`CaptureControlsBar` owns the flash control UI inside `CaptureButton.swift`. The user-visible behaviour is small but easy to regress while continuing capture UI work:

- flash starts in auto mode.
- tapping the flash button cycles auto -> on -> off -> auto.
- each mode uses the expected SF Symbol in the camera control.

This should be a focused capture-control seam rather than inline switch logic inside the SwiftUI control bar.

## Acceptance Criteria

- Characterize flash mode behaviour before production edits.
- Preserve flash cycle order:
  - auto advances to on.
  - on advances to off.
  - off advances back to auto.
- Preserve the current system image contract:
  - auto uses `bolt.badge.automatic`.
  - on uses `bolt.fill`.
  - off uses `bolt.slash`.
- Keep `CaptureButton.swift` below 500 LOC.
- Do not change capture execution, camera setup, image processing, or extraction behaviour.
- Run focused capture flash-mode tests.
- Run nearby capture tests.
- Run simulator build and attempt capture UI smoke.

## Implementation

- Added `CaptureFlashMode` as a small value seam for flash cycle and icon metadata.
- Updated `CaptureControlsBar` to use `CaptureFlashMode.next` and `CaptureFlashMode.icon`.
- Added focused characterization coverage in `CaptureFlashModeTests`.

## LOC Impact

- `BookQuotes/Components/CaptureButton.swift`: 433 LOC.
- `BookQuotes/Components/CaptureFlashMode.swift`: 23 LOC.
- `BookQuotesTests/Unit/Capture/CaptureFlashModeTests.swift`: 17 LOC.

## Verification

- Focused camera/capture-control gate on 2026-07-01:
  - 29 tests executed.
  - 0 failures.
  - Included `CaptureFlashModeTests`, nearby camera policy/service tests, camera framing tests, image preprocessor tests, and quote-capture processing/session tests.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

XCUITest capture UI automation remains tracked separately by issue 081.

## Follow-Up

- Keep further capture-control metadata changes in `CaptureFlashModeTests` before touching `CaptureControlsBar`.
