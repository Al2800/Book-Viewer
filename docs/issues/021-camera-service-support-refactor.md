# Camera Service Support Refactor

Status: `closed`

Priority: medium

## Problem

`CameraService.swift` was 490 LOC and mixed AVFoundation camera authorization/session/capture concerns with support behaviours:

- user-facing `CameraError` descriptions;
- upload image compression and resize logic.

Those support behaviours are independently tested and do not need to live in the camera session manager.

## Acceptance Criteria

- [x] Characterize camera error and compression behaviour before production edits.
- [x] Keep `CameraService` public upload-compression API unchanged.
- [x] Preserve all `CameraError` cases and user-facing error descriptions.
- [x] Preserve upload compression behaviour, max-dimension aspect-ratio resize, and JPEG quality parameter.
- [x] Keep authorization, session setup, preview creation, session start/stop, capture, switching, focus, and cleanup in `CameraService`.
- [x] Move `CameraService.swift` further below 500 LOC.
- [x] Build passes after extraction.
- [x] Focused `CameraServiceTests` pass after extraction.
- [x] Architecture and verification docs record module ownership, test commands, LOC delta, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Services/CameraServiceSupport.swift`.
- Moved `CameraError` and `CameraImageCompressor` into the support module.
- Kept `CameraService.compressForUpload(...)` as a compatibility API that delegates to `CameraImageCompressor`.

## LOC Result

- `CameraService.swift`: 490 LOC -> 418 LOC.
- `CameraServiceSupport.swift`: 84 LOC.

## Residual Risk / Next Slice

- `CameraService.swift` still has existing Swift 6 concurrency warnings around detached session start/stop and existing AVFoundation deprecation warnings.
- A follow-on camera slice should characterize mock-camera/session state before changing session concurrency behaviour.
- 2026-07-01: issue 063 added `CameraAuthorizationPolicy` for deterministic camera status decisions. Future authorization status changes should start in `CameraAuthorizationPolicyTests`; live permission prompting remains in `CameraService`.
