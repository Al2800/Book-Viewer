# Camera Permission Service Policy Characterization

## Scope

This slice routes `CameraPermissionService.checkStatus()` through `CameraAuthorizationPolicy` while preserving the richer permission state used by camera permission UI.

## Current Behaviour Characterized

- `.authorized` maps to `CameraPermissionService.PermissionStatus.authorized`.
- `.notDetermined` maps to `CameraPermissionService.PermissionStatus.notDetermined`.
- `.denied` maps to `CameraPermissionService.PermissionStatus.denied`.
- `.restricted` maps to `CameraPermissionService.PermissionStatus.restricted`.
- The coarser `CameraAuthorizationDecision` still treats denied and restricted as not authorized and not promptable.

## Missing Test Surface Before This Slice

Issue 063 characterized the yes/no authorization decision, but not the richer permission status mapping needed by `CameraPermissionService`. Without that coverage, reusing the policy would risk collapsing restricted access into denied access in the permission UI.

## Refactor Decision

Add `CameraAuthorizationPolicy.permissionStatus(for:)` and leave `CameraPermissionService` responsible for:

- mock-camera fast path;
- live `AVCaptureDevice.requestAccess(for: .video)`;
- user-facing status storage;
- Settings navigation;
- app-active status refresh and haptic feedback.

## Acceptance Coverage Added

- `CameraAuthorizationPolicyTests.testPermissionStatusMappingPreservesDeniedAndRestrictedDistinction`

## Non-Goals

- No change to permission request prompting.
- No change to `CameraPermissionView`.
- No change to real camera setup/capture.
- No change to session start/stop concurrency.
