# Onboarding Session and Capture Queue Retry Scheduler Refactor Verification

Date: 2026-06-30

## Changes

- Added `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`.
- Added `BookQuotes/Services/CaptureQueueRetryScheduler.swift`.
- Added focused unit tests for both modules.
- Updated `OnboardingView` to delegate route/session mutation.
- Updated `CaptureQueueManager` to delegate retry task storage, replacement, and cancellation.

## LOC

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 162 LOC -> 160 LOC.
- `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`: 30 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 307 LOC -> 298 LOC.
- `BookQuotes/Services/CaptureQueueRetryScheduler.swift`: 30 LOC.

## Commands

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnboardingSessionStateTests -only-testing:BookQuotesTests/CaptureQueueRetrySchedulerTests
```

Result: failed before implementation because `OnboardingSessionState` and `CaptureQueueRetryScheduler` were missing; passed after implementation.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnboardingFlowPolicyTests -only-testing:BookQuotesTests/OnboardingCompletionStoreTests -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests -only-testing:BookQuotesTests/OnboardingSessionStateTests -only-testing:BookQuotesTests/CaptureQueueProcessingPreferencesTests -only-testing:BookQuotesTests/CaptureQueueRetrySchedulerTests -only-testing:BookQuotesTests/CaptureQueueSupportTests -only-testing:BookQuotesTests/CaptureQueueStoreTests -only-testing:BookQuotesTests/CaptureQueueManagerTests
```

Result: passed.

```sh
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/OnboardingFlowTests/testOnboarding_SignInStep_DisplaysCorrectElements
```

Result: failed before app assertions:

```text
BookQuotesUITests-Runner encountered an error. The test runner failed to initialize for UI testing.
Underlying Error: Timed out waiting for AX loaded notification
```

## Residual Risk

- Onboarding UI smoke remains blocked by the UI runner AX bootstrap failure in this environment.
- `CaptureQueueManager` still owns processing task lifecycle and network observation. Those are valid future seams, but should be characterized with a controllable network/clock adapter before extraction.
