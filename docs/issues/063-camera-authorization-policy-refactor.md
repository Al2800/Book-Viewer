# Issue 063: Camera Authorization Policy Refactor

Status: `closed`

## Context

`CameraService.swift` is below the 500 LOC target, but it still repeated deterministic authorization status mapping inside the service. That logic is user-facing because it decides whether the camera is usable, whether to prompt, or whether to deny access without prompting.

This slice extracts only the deterministic authorization decision. Live permission prompting remains in `CameraService`.

## Acceptance Criteria

- [x] Characterize authorized, not-determined, denied, and restricted camera statuses before changing `CameraService`.
- [x] Preserve mock-camera behaviour: mock mode remains authorized without AVFoundation calls.
- [x] Preserve `checkAuthorization()` observable behaviour.
- [x] Preserve `requestAuthorization()` observable behaviour.
- [x] Keep live `AVCaptureDevice.requestAccess(for: .video)` in `CameraService`.
- [x] Move deterministic status-to-decision mapping out of `CameraService`.
- [x] Keep `CameraService.swift` below 500 LOC.
- [x] Register new source and tests in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused camera tests when the local Xcode runner is healthy.
- [x] Run camera simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Services/CameraAuthorizationPolicy.swift`.
- Added `CameraAuthorizationDecision`.
- Added `CameraAuthorizationPolicy.decision(for:)`.
- Added `BookQuotesTests/Unit/Services/CameraAuthorizationPolicyTests.swift`.
- Updated `CameraService.checkAuthorization()` and `CameraService.requestAuthorization()` to use the policy.

## LOC Impact

- `BookQuotes/Services/CameraService.swift`: 415 LOC -> 405 LOC.
- `BookQuotes/Services/CameraAuthorizationPolicy.swift`: 30 LOC.
- `BookQuotesTests/Unit/Services/CameraAuthorizationPolicyTests.swift`: 32 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused camera/capture-control gate on 2026-07-01:
    - 29 tests executed.
    - 0 failures.
    - Included `CameraAuthorizationPolicyTests`, `CameraServiceTests`, and nearby camera/capture tests.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

Real camera hardware behaviour remains tracked by issue 014.

## Follow-Up

- 2026-07-01: issue 064 consolidated `CameraPermissionService.checkStatus()` through `CameraAuthorizationPolicy.permissionStatus(for:)` while preserving restricted status.
- Session start/stop concurrency warnings remain outside this slice.
