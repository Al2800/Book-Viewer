# Camera Authorization Policy Characterization

## Scope

This slice isolates deterministic camera authorization status mapping from `CameraService`.

## Current Behaviour Characterized

- `.authorized` means the camera is authorized and no access request is needed.
- `.notDetermined` means the camera is not authorized yet and should request access.
- `.denied` means the camera is not authorized and should not request access.
- `.restricted` means the camera is not authorized and should not request access.
- Unknown future statuses deny access by default.

## Missing Test Surface Before This Slice

`CameraServiceTests` covered error descriptions, upload compression, and preview-size fallback. The authorization status mapping was embedded directly inside `CameraService.checkAuthorization()` and `CameraService.requestAuthorization()`, making it harder to change without testing through live AVFoundation state.

## Refactor Decision

Create `CameraAuthorizationPolicy` as a small deterministic seam:

- `CameraAuthorizationDecision.authorized`
- `CameraAuthorizationDecision.needsRequest`
- `CameraAuthorizationDecision.denied`

`CameraService` still owns live AVFoundation calls and observable state mutation. The policy only answers what a given status means.

## Acceptance Coverage Added

- `CameraAuthorizationPolicyTests.testAuthorizedStatusAllowsCameraWithoutPrompting`
- `CameraAuthorizationPolicyTests.testNotDeterminedStatusRequestsAccess`
- `CameraAuthorizationPolicyTests.testDeniedAndRestrictedStatusesDenyCameraWithoutPrompting`

## Non-Goals

- No change to real permission prompting.
- No change to mock-camera mode.
- No change to session setup, preview, capture, switching, focus, or cleanup.
- No change to `CameraPermissionService` yet.
