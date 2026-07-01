# Onboarding and Capture Queue Network Monitoring Refactor Verification

Date: 2026-06-30

## Changes

- Added onboarding explicit-step characterization in `OnboardingSessionStateTests`.
- Added `BookQuotes/Services/CaptureQueueNetworkMonitoring.swift`.
- Updated `CaptureQueueManager` and `CaptureQueueShared` to depend on the queue connectivity seam.
- Added a deterministic injected-network test to `CaptureQueueManagerTests`.

## LOC

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 160 LOC.
- `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`: 30 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 298 LOC.
- `BookQuotes/Services/CaptureQueueNetworkMonitoring.swift`: 10 LOC.

## Commands

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnboardingSessionStateTests -only-testing:BookQuotesTests/OnboardingFlowPolicyTests -only-testing:BookQuotesTests/OnboardingCompletionStoreTests -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests -only-testing:BookQuotesTests/CaptureQueueManagerTests/testStartUsesInjectedNetworkMonitorAndRemainsIdleWhenOffline -only-testing:BookQuotesTests/CaptureQueueProcessingPreferencesTests -only-testing:BookQuotesTests/CaptureQueueRetrySchedulerTests -only-testing:BookQuotesTests/CaptureQueueSupportTests -only-testing:BookQuotesTests/CaptureQueueStoreTests
```

Result: passed.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CaptureQueueManagerTests
```

Result: passed.

```sh
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/OnboardingFlowTests/testOnboarding_WelcomeCarousel_DisplaysAllPages
```

Result: failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.
