# Verification: Onboarding and Capture Queue Reconciliation

Date: 2026-07-01

## Scope

This note reconciles onboarding/capture queue issues that were previously left `in_progress` because earlier verification was blocked by local Xcode/CoreSimulator startup failures.

Issues reconciled:

- `053-onboarding-and-capture-queue-characterization-surface-refactor.md`
- `057-onboarding-and-capture-queue-processing-outcome-refactor.md`
- `061-onboarding-and-capture-queue-manager-dependencies-refactor.md`
- `065-onboarding-step-and-capture-queue-retry-characterization.md`
- `066-capture-queue-retry-coordinator-refactor.md`
- `067-onboarding-media-subscription-plan-refactor.md`
- `068-onboarding-sign-in-copy-policy-refactor.md`
- `069-onboarding-welcome-carousel-state-refactor.md`
- `070-onboarding-marking-selection-state-refactor.md`
- `071-capture-queue-command-mutation-refactor.md`
- `075-capture-queue-stats-reporter-refactor.md`
- `076-capture-queue-manager-test-surface-refactor.md`

## Focused Characterization Gate

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/CaptureQueueItemTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests \
  -only-testing:BookQuotesTests/CaptureQueueProcessingTests \
  -only-testing:BookQuotesTests/CaptureQueueStatsReporterTests \
  -only-testing:BookQuotesTests/CaptureQueueRetryCoordinatorTests \
  -only-testing:BookQuotesTests/CaptureQueueRetrySchedulerTests \
  -only-testing:BookQuotesTests/CaptureQueueNetworkObserverTests \
  -only-testing:BookQuotesTests/CaptureQueueNetworkTransitionTests \
  -only-testing:BookQuotesTests/CaptureQueueProcessingPreferencesTests \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/OnboardingSessionStateTests \
  -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests \
  -only-testing:BookQuotesTests/OnboardingCompletionActionTests \
  -only-testing:BookQuotesTests/OnboardingCompletionStoreTests \
  -only-testing:BookQuotesTests/OnboardingMediaSubscriptionPlanTests \
  -only-testing:BookQuotesTests/OnboardingSignInCopyPolicyTests \
  -only-testing:BookQuotesTests/OnboardingWelcomeCarouselStateTests \
  -only-testing:BookQuotesTests/OnboardingMarkingSelectionStateTests
```

Result: passed.

- 84 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-51-10-+0100.xcresult`.

## Broad Unit Gate

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' -only-testing:BookQuotesTests
```

Result: passed.

- 548 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-47-23-+0100.xcresult`.

## Simulator Smoke

Onboarding reset:

```sh
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --reset-onboarding --skip-auth -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-onboarding-reset-smoke.png
```

Result: passed.

- App launched.
- Screenshot showed the onboarding welcome screen.

Seeded/mock-camera:

```sh
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --preload-library-test-data --mock-camera -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png
```

Result: passed.

- App launched.
- Screenshot showed seeded Library data with 3 books and 6 quotes.

## LOC Snapshot

- `BookQuotes/Services/CaptureQueueManager.swift`: 303 LOC.
- `BookQuotes/Features/Onboarding/OnboardingStepViews.swift`: 254 LOC.
- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 148 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`: 292 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTestDoubles.swift`: 173 LOC.

All onboarding/capture queue files in this reconciliation are below the 500 LOC target.

## Residual Risk

XCUITest UI automation still fails before app assertions with the AX runner initialization issue tracked in `docs/issues/081-xcuitest-ax-runner-initialization.md`.
