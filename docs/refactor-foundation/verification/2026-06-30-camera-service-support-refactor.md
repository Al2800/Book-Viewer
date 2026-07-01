# Camera Service Support Refactor - 2026-06-30

## Scope

- Extracted `CameraError` and upload image compression from `Services/CameraService.swift` into `Services/CameraServiceSupport.swift`.
- Preserved `CameraService.compressForUpload(_:maxDimension:quality:)` by delegating to `CameraImageCompressor`.
- Kept AVFoundation session, capture, preview, switching, focus, and cleanup behaviour in `CameraService`.

## LOC Result

- `BookQuotes/Services/CameraService.swift`: 490 LOC -> 418 LOC.
- `BookQuotes/Services/CameraServiceSupport.swift`: 84 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Focused CameraService tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CameraServiceTests
```

Result before edits:

- Passed.
- Runtime: `30.099` seconds.

Result after refactor:

- Passed.
- Runtime: `31.138` seconds.

Notes:

- Xcode emitted existing AVFoundation deprecation warnings and Swift 6 concurrency warnings in `CameraService`.
- No tests were edited for this slice.

## Residual Risk

- Existing session start/stop detached-task warnings remain and should be addressed in a separate characterization slice.
- The current focused tests cover error descriptions and compression, not real camera hardware behaviour.
