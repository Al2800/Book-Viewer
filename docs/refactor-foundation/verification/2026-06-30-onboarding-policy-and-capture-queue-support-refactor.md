# Onboarding Policy and Capture Queue Support Verification

Date: 2026-06-30

Issue: `docs/issues/024-onboarding-policy-and-capture-queue-support-refactor.md`

## Changes

- Added `OnboardingFlowPolicy` for initial onboarding step and post-sign-in route decisions.
- Added `CaptureQueueSupport` for retry-delay selection, queue item fetch descriptors, pending-item descriptor creation, and queue stats aggregation.
- Added focused unit tests for both helper seams.
- Kept `OnboardingView` as the SwiftUI coordinator for service injection, sheet presentation, step state, completion side effects, haptics, and dismissal.
- Kept `CaptureQueueManager` as the actor for queue lifecycle, persistence, processing orchestration, retry task scheduling, stats publication, and network observation.

## LOC Delta

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 154 LOC -> 168 LOC.
- `BookQuotes/Features/Onboarding/OnboardingFlowPolicy.swift`: 21 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 416 LOC -> 378 LOC.
- `BookQuotes/Services/CaptureQueueSupport.swift`: 59 LOC.

## Verification

Latest re-check after the onboarding and queue split:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests
```

Result:

- Passed.
- Runtime: `31.961` seconds.

Focused new unit tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests
```

Result:

- Passed.
- Runtime: `36.515` seconds.

Capture queue characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result:

- Passed.
- Runtime: `34.804` seconds.

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Onboarding UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests
```

Result:

- Blocked by XCTest/simulator runner bootstrap.
- Latest run failed before app assertions with: `The test runner failed to initialize for UI testing. (Underlying Error: Timed out waiting for AX loaded notification)`.
- Earlier runs also repeated `IDELaunchParametersSnapshot` debugger-version errors and never reached app assertions.

## Residual Risk

- Onboarding user-visible behavior is covered by pure route tests and unchanged SwiftUI composition, but the UI smoke still needs a healthy simulator/XCTest runner to assert the actual screen sequence.
- Queue retry task scheduling is preserved structurally, but a future slice should introduce a controllable clock to characterize delayed retry scheduling without real sleeps.
