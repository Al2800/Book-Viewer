# Issue 033: Camera Preview Size Store Refactor

Status: closed

## Problem

`CameraService` was already below the 500 LOC target, but it still directly owned the fallback policy for preview sizes used during cropping. That fallback matters because quote capture should send the same framed region to extraction that the user saw in the preview.

This policy is small, but it is easy to break when adjusting camera framing, preview gravity, or capture flow layout. It needs a named module and public adapter-level characterization.

## Acceptance Criteria

- Characterize preview-size fallback before changing `CameraService`.
- Preserve the behavior that invalid layout sizes do not erase the last valid preview layout size.
- Preserve preference for a valid live preview-layer size when available.
- Preserve `nil` until some valid preview size exists.
- Keep `CameraService.swift` below 500 LOC.
- Add focused tests for the extracted module and the public `CameraService` behavior.
- Run nearby camera/capture preparation tests.
- Run simulator build.
- Attempt quote-capture simulator UI smoke and record result.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Services/CameraPreviewSizeStore.swift`.
- Added `BookQuotesTests/Unit/Services/CameraPreviewSizeStoreTests.swift`.
- Added `CameraServiceTests.testPreviewSizeForCroppingPreservesLastValidLayoutSize`.
- `CameraService` now delegates preview-size validation and fallback to `CameraPreviewSizeStore`.

## LOC Result

- `BookQuotes/Services/CameraService.swift`: 418 LOC -> 415 LOC.
- `BookQuotes/Services/CameraPreviewSizeStore.swift`: 22 LOC.

## Verification

- Focused camera characterization passed before and after production wiring:
  - `BookQuotesTests/CameraServiceTests/testPreviewSizeForCroppingPreservesLastValidLayoutSize`
  - `BookQuotesTests/CameraPreviewSizeStoreTests`
- Nearby camera/capture tests passed:
  - `BookQuotesTests/CameraPreviewSizeStoreTests`
  - `BookQuotesTests/CameraServiceTests`
  - `BookQuotesTests/CameraFramingProfileTests`
  - `BookQuotesTests/QuoteCaptureImageProcessorTests`
  - `BookQuotesTests/ImagePreprocessorTests`
- Simulator build passed.
- Quote-capture UI smoke was attempted but failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- Real-device/TestFlight verification remains required for perceived zoom and lens/framing behavior.
- The next camera slice should focus on actual lens/zoom opening state only after real-device evidence is available, not on simulator-only layout signals.
