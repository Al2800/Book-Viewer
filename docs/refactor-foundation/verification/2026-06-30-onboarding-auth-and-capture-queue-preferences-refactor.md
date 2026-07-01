# Onboarding Auth and Capture Queue Preferences Refactor Verification

Date: 2026-06-30

## Changes

- Added `BookQuotes/Features/Onboarding/OnboardingAuthSkipPolicy.swift`.
- Added `BookQuotes/Services/CaptureQueueProcessingPreferences.swift`.
- Added focused unit tests for both modules.
- Updated `OnboardingView` to delegate auth-skip decisions.
- Updated `CaptureQueueManager` to delegate auto-process preference lookup.
- Corrected the project-file path for `BookQuotes/Services/CameraPreviewSizeStore.swift` so the app target can build with the already-added file.

## LOC

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 167 LOC -> 162 LOC.
- `BookQuotes/Features/Onboarding/OnboardingAuthSkipPolicy.swift`: 29 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 305 LOC -> 307 LOC.
- `BookQuotes/Services/CaptureQueueProcessingPreferences.swift`: 19 LOC.

## Commands

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests -only-testing:BookQuotesTests/CaptureQueueProcessingPreferencesTests
```

Result: passed after the red/green implementation.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests -only-testing:BookQuotesTests/OnboardingFlowPolicyTests -only-testing:BookQuotesTests/OnboardingCompletionStoreTests -only-testing:BookQuotesTests/CaptureQueueProcessingPreferencesTests -only-testing:BookQuotesTests/CaptureQueueSupportTests -only-testing:BookQuotesTests/CaptureQueueStoreTests -only-testing:BookQuotesTests/CaptureQueueManagerTests
```

Result: passed.

```sh
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/OnboardingFlowTests/testOnboarding_WelcomeCarousel_DisplaysAllPages
```

Result: failed before app assertions:

```text
BookQuotesUITests-Runner encountered an error. The test runner failed to initialize for UI testing.
Underlying Error: Timed out waiting for AX loaded notification
```

## Residual Risk

- Onboarding simulator smoke remains blocked by the UI runner AX bootstrap failure in this environment.
- Capture queue retry scheduling remains actor/task based and should not be extracted until a controllable clock or scheduler seam is characterized.
