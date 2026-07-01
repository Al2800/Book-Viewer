# Camera Preview Size Store Refactor Characterization

Date: 2026-06-30

## Scope

This slice characterized and extracted the preview-size fallback policy used by camera capture cropping.

The goal was not to change the camera framing contract. The goal was to isolate the size fallback rule so future framing and lens changes have a smaller test surface.

## Characterized Behavior

- `CameraService.updatePreviewSize` ignores zero and negative layout sizes.
- `CameraService.currentPreviewSizeForCropping` keeps returning the last valid layout size after invalid updates.
- `CameraPreviewSizeStore` prefers a valid live preview-layer size over the remembered layout size.
- `CameraPreviewSizeStore` falls back to the last valid layout size when the preview-layer size is invalid.
- `CameraPreviewSizeStore` returns `nil` until a valid preview-layer or layout size exists.

## Refactor

- Replaced `CameraService.lastPreviewSize` with `CameraPreviewSizeStore`.
- Kept `CameraService` as the AVFoundation adapter and public UI-facing service.
- Kept preview-size policy pure and independently testable.

## Verification

See `docs/refactor-foundation/verification/2026-06-30-camera-preview-size-store-refactor.md`.
