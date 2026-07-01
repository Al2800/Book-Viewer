# Onboarding Completion and Capture Queue Store Verification

Date: 2026-06-30

Issue: `docs/issues/029-onboarding-completion-and-capture-queue-store-refactor.md`

## Changes

- Added `OnboardingCompletionStore` for onboarding completion flags.
- Added `CaptureQueueStore` for queue image storage, SwiftData queue mutations, stats, and pending-item lookup.
- Updated `OnboardingView` to delegate completion persistence.
- Updated `CaptureQueueManager` to delegate queue mutations while retaining lifecycle, network observation, processing, retry task cancellation, and stats publication.
- Added `OnboardingCompletionStoreTests`.
- Added `CaptureQueueStoreTests`.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 168 LOC -> 167 LOC.
- `BookQuotes/Features/Onboarding/OnboardingCompletionStore.swift`: 14 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 378 LOC -> 305 LOC.
- `BookQuotes/Services/CaptureQueueStore.swift`: 98 LOC.

## Verification

New seam tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnboardingCompletionStoreTests \
  -only-testing:BookQuotesTests/CaptureQueueStoreTests
```

Result:

- Passed.
- Runtime: `29.663` seconds.

Wider characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/OnboardingCompletionStoreTests \
  -only-testing:BookQuotesTests/CaptureQueueStoreTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/CaptureQueueItemTests
```

Result:

- Passed.
- Runtime: `29.575` seconds.

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

- Failed before app assertions with XCTest runner initialization error:
  `The test runner failed to initialize for UI testing. (Underlying Error: Timed out waiting for AX loaded notification)`.
- Runtime before failure: `103.346` seconds.

## Residual Risk

- Onboarding user-visible flow still needs a healthy XCTest UI runner to validate the full screen sequence.
- Queue retry scheduling still uses real `Task.sleep`; a future slice should add a controllable retry scheduler or clock before changing delayed retry behavior.
