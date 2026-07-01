# Verification: Onboarding Routing and Capture Queue Start Policy Refactor

Date: 2026-07-01

## Commands

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnboardingSessionStateTests -only-testing:BookQuotesTests/CaptureQueueSupportTests
```

Result: RED first, then passed after implementation.

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests \
  -only-testing:BookQuotesTests/OnboardingSessionStateTests \
  -only-testing:BookQuotesTests/OnboardingCompletionActionTests \
  -only-testing:BookQuotesTests/OnboardingCompletionStoreTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests \
  -only-testing:BookQuotesTests/CaptureQueueProcessingPreferencesTests \
  -only-testing:BookQuotesTests/CaptureQueueRetrySchedulerTests \
  -only-testing:BookQuotesTests/CaptureQueueNetworkTransitionTests \
  -only-testing:BookQuotesTests/CaptureQueueNetworkObserverTests \
  -only-testing:BookQuotesTests/CaptureQueueStoreTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests
```

Result: passed.

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests/testOnboarding_WelcomeCarousel_SkipButtonNavigatesToSignIn \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testCaptureTab_CaptureButton_Exists
```

Result: failed before app assertions because the UI test runner did not initialize:

```text
Timed out waiting for AX loaded notification
```

## Notes

Existing warning noise remains in unrelated files:

- Swift 6 actor/sendability warnings in search, quote save, batch processing, and test infrastructure.
- `CaptureQueueManager.statsPublisher` has an existing `nonisolated(unsafe)` warning.

Simulator build and UI smoke are recorded after the test run in the current work session.
