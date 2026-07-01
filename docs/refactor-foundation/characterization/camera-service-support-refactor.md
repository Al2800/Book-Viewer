# Camera Service Support Characterization

Date: 2026-06-30

Issue: `docs/issues/021-camera-service-support-refactor.md`

## Baseline Behaviour

This slice keeps camera service behaviour intact while extracting support code that does not own the AVFoundation session.

Camera error behaviours:

- `CameraError.notAuthorized` describes unauthorized camera access.
- `CameraError.cameraUnavailable` describes unavailable camera hardware.
- `CameraError.cannotAddInput` describes input setup failure.
- `CameraError.cannotAddOutput` describes output setup failure.
- `CameraError.imageProcessingFailed` describes image decode/processing failure.
- Other existing error cases remain available for runtime capture/session failures.

Upload compression behaviours:

- `CameraService.compressForUpload(_:maxDimension:quality:)` remains callable.
- It returns JPEG data for a valid image.
- It preserves aspect ratio when resizing to `maxDimension`.
- It passes through the caller-provided JPEG quality.

Camera service ownership retained:

- Authorization checks and requests.
- Session setup and capture input/output wiring.
- Preview layer creation and preview-size tracking.
- Session start/stop.
- Real and mock photo capture.
- Camera switching and focus.
- Capture cleanup.

## Characterization Used

Focused camera baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CameraServiceTests
```

Result before edits:

- Passed.
- Runtime: `30.099` seconds.

## Extracted Module

- `CameraServiceSupport.swift`: `CameraError`, `CameraImageCompressor`, and `CameraService.compressForUpload(...)` compatibility extension.

## Non-Goals

- No change to camera authorization, real camera setup, mock camera setup, preview layer creation, session start/stop, capture timeout, delegate handling, camera switching, focus, or cleanup.
- No change to tests to make this pass.
