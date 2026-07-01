# Camera Preview Size Store Refactor Verification

Date: 2026-06-30

## Changes

- Added `BookQuotes/Services/CameraPreviewSizeStore.swift`.
- Added `BookQuotesTests/Unit/Services/CameraPreviewSizeStoreTests.swift`.
- Added `CameraServiceTests.testPreviewSizeForCroppingPreservesLastValidLayoutSize`.
- Replaced `CameraService.lastPreviewSize` with `CameraPreviewSizeStore`.

## LOC

- `BookQuotes/Services/CameraService.swift`: 418 LOC -> 415 LOC.
- `BookQuotes/Services/CameraPreviewSizeStore.swift`: 22 LOC.

## Commands

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CameraServiceTests/testPreviewSizeForCroppingPreservesLastValidLayoutSize -only-testing:BookQuotesTests/CameraPreviewSizeStoreTests
```

Result: passed before and after production wiring.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CameraPreviewSizeStoreTests -only-testing:BookQuotesTests/CameraServiceTests -only-testing:BookQuotesTests/CameraFramingProfileTests -only-testing:BookQuotesTests/QuoteCaptureImageProcessorTests -only-testing:BookQuotesTests/ImagePreprocessorTests
```

Result: passed.

```sh
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testImageReview_ShowsQualityIndicator
```

Result: failed before app assertions:

```text
BookQuotesUITests-Runner encountered an error. The test runner failed to initialize for UI testing.
Underlying Error: Timed out waiting for AX loaded notification
```

## Residual Risk

- Simulator tests do not validate real camera focal length, perceived zoom, or physical-device preview framing.
- Real-device/TestFlight smoke remains required before treating issue 014 as fully accepted.
