# Issue 064: Camera Permission Service Policy Refactor

Status: `closed`

## Context

Issue 063 introduced `CameraAuthorizationPolicy` for the yes/no authorization decision used by `CameraService`. `CameraPermissionService` still had its own AVFoundation status switch because it needs a richer state model for user-facing permission UI: not determined, authorized, denied, and restricted.

This slice deepens the policy seam so `CameraPermissionService` can reuse it without losing the denied/restricted distinction.

## Acceptance Criteria

- [x] Characterize camera permission status mapping before changing `CameraPermissionService`.
- [x] Preserve `.authorized`, `.notDetermined`, `.denied`, and `.restricted` status mapping.
- [x] Preserve `CameraService` authorization decision behaviour from issue 063.
- [x] Preserve mock-camera behaviour in `CameraPermissionService`.
- [x] Keep live `AVCaptureDevice.requestAccess(for: .video)` in `CameraPermissionService`.
- [x] Remove duplicated authorization status switch from `CameraPermissionService`.
- [x] Keep `CameraPermissionService.swift` below 500 LOC.
- [x] Update architecture and verification docs.
- [x] Run focused camera permission tests when the local Xcode runner is healthy.
- [x] Run camera simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `CameraAuthorizationPolicy.permissionStatus(for:)`.
- Added characterization coverage for preserving the denied/restricted distinction.
- Updated `CameraPermissionService.checkStatus()` to use the shared policy.
- Left `CameraPermissionService.requestPermission()` responsible for live permission prompting and granted/denied mutation.

## LOC Impact

- `BookQuotes/Services/CameraPermissionService.swift`: 152 LOC -> 142 LOC.
- `BookQuotes/Services/CameraAuthorizationPolicy.swift`: 30 LOC -> 47 LOC.
- `BookQuotesTests/Unit/Services/CameraAuthorizationPolicyTests.swift`: 32 LOC -> 39 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused camera/capture-control gate on 2026-07-01:
    - 29 tests executed.
    - 0 failures.
    - Included `CameraAuthorizationPolicyTests`, `CameraPermissionServiceTests`, `CameraServiceTests`, and nearby camera/capture tests.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

Real permission prompting and camera hardware behaviour remain tied to simulator/device validation in issue 014.

## Follow-Up

- Real camera permission UX still needs simulator/device validation when the simulator service is available.
- Session start/stop concurrency warnings remain outside this slice.

## 2026-07-17 Authorized-Launch Regression

Build 43 briefly displayed the full `Enable Camera Access` screen when an already-authorized user
opened capture, then replaced it with the live preview. Both `CameraPermissionService` and
`CameraService` started from placeholder unauthorized state and only read AVFoundation status
after SwiftUI's first render.

- `CameraPermissionService` now initializes from the current AVFoundation authorization status.
- `CameraService` now initializes `isAuthorized` from the same shared authorization policy.
- First-time users still receive the explicit permission screen and must select Enable Camera
  Access; already-authorized users proceed directly to camera setup without misleading UI.
- Focused simulator verification passed 15 camera authorization, permission, and service tests
  with no failures on iPhone 17 / iOS 26.5.
