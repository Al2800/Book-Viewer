# Verification: Camera Policy and Capture Control Reconciliation

Date: 2026-07-01

## Scope

This note reconciles camera policy/capture-control issues that were previously left `in_progress` because earlier verification was blocked by local Xcode/CoreSimulator startup failures.

Issues reconciled:

- `048-capture-flash-mode-refactor.md`
- `063-camera-authorization-policy-refactor.md`
- `064-camera-permission-service-policy-refactor.md`

Issue `014-camera-preview-framing-and-guidance.md` remains in progress because it requires real-device/TestFlight validation of perceived camera zoom, preview framing, and physical capture quality.

## Focused Characterization Gate

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/CaptureFlashModeTests \
  -only-testing:BookQuotesTests/CameraAuthorizationPolicyTests \
  -only-testing:BookQuotesTests/CameraPermissionServiceTests \
  -only-testing:BookQuotesTests/CameraServiceTests \
  -only-testing:BookQuotesTests/CameraPreviewSizeStoreTests \
  -only-testing:BookQuotesTests/CameraFramingProfileTests \
  -only-testing:BookQuotesTests/QuoteCaptureImageProcessorTests \
  -only-testing:BookQuotesTests/QuoteCaptureSessionStoreTests \
  -only-testing:BookQuotesTests/ImagePreprocessorTests
```

Result: passed.

- 29 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-59-52-+0100.xcresult`.

## Broad Unit Gate

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' -only-testing:BookQuotesTests
```

Result: passed.

- 548 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-47-23-+0100.xcresult`.

## Simulator Smoke

Manual seeded/mock-camera launch:

```sh
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --preload-library-test-data --mock-camera -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png
```

Result: passed.

- App launched.
- Screenshot showed seeded Library data with 3 books and 6 quotes.

## LOC Snapshot

- `BookQuotes/Services/CameraService.swift`: 405 LOC.
- `BookQuotes/Services/CameraPermissionService.swift`: 142 LOC.
- `BookQuotes/Services/CameraServiceSupport.swift`: 84 LOC.
- `BookQuotes/Services/CameraAuthorizationPolicy.swift`: 47 LOC.
- `BookQuotes/Components/CaptureFlashMode.swift`: 23 LOC.
- `BookQuotes/Services/CameraPreviewSizeStore.swift`: 22 LOC.

All camera policy/capture-control files in this reconciliation are below the 500 LOC target.

## Residual Risk

XCUITest UI automation still fails before app assertions with the AX runner initialization issue tracked in `docs/issues/081-xcuitest-ax-runner-initialization.md`.

Real camera hardware validation remains required for issue 014.
