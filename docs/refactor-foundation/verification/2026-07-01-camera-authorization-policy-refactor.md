# Camera Authorization Policy Verification

## Changed Files

- `BookQuotes/Services/CameraAuthorizationPolicy.swift`
- `BookQuotes/Services/CameraService.swift`
- `BookQuotesTests/Unit/Services/CameraAuthorizationPolicyTests.swift`
- `BookQuotes.xcodeproj/project.pbxproj`
- `docs/ARCHITECTURE.md`
- `docs/issues/README.md`
- `docs/issues/063-camera-authorization-policy-refactor.md`
- `docs/refactor-foundation/characterization/camera-authorization-policy-refactor.md`

## LOC

```text
405 BookQuotes/Services/CameraService.swift
 30 BookQuotes/Services/CameraAuthorizationPolicy.swift
 84 BookQuotes/Services/CameraServiceSupport.swift
 32 BookQuotesTests/Unit/Services/CameraAuthorizationPolicyTests.swift
 41 BookQuotesTests/Unit/Services/CameraServiceTests.swift
```

## Static Verification

```sh
git diff --check
```

Result: passed.

```sh
plutil -lint BookQuotes.xcodeproj/project.pbxproj
```

Result: passed.

## Focused Test Attempt

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CameraAuthorizationPolicyTests -only-testing:BookQuotesTests/CameraServiceTests -only-testing:BookQuotesTests/CameraPreviewSizeStoreTests
```

Result: blocked before compilation by the local Xcode runner:

```text
DVTFilePathFSEvents: Failed to start fs event stream.
Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error".
```

## Simulator Smoke Attempt

```sh
xcrun simctl list devices | head -30
```

Result: blocked because CoreSimulatorService is unavailable:

```text
Error Domain=NSPOSIXErrorDomain Code=61 "Connection refused"
Unable to lookup com.apple.CoreSimulator.CoreSimulatorService
```

## Residual Risk

- The project file lints and the new tests are registered, but tests could not execute in this environment.
- `CameraPermissionService` has separate authorization handling and remains a follow-up consolidation target.
- Real camera hardware behaviour still needs device/TestFlight validation.
