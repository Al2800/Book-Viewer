# Onboarding and Capture Queue Manager Dependencies Verification

## Changed Files

- `BookQuotes/Services/CaptureQueueDependencies.swift`
- `BookQuotes/Services/CaptureQueueManager.swift`
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`
- `BookQuotes.xcodeproj/project.pbxproj`
- `docs/ARCHITECTURE.md`
- `docs/issues/README.md`
- `docs/issues/061-onboarding-and-capture-queue-manager-dependencies-refactor.md`
- `docs/refactor-foundation/characterization/onboarding-and-capture-queue-manager-dependencies-refactor.md`

## LOC

```text
160 BookQuotes/Features/Onboarding/OnboardingView.swift
295 BookQuotes/Services/CaptureQueueManager.swift
 28 BookQuotes/Services/CaptureQueueDependencies.swift
258 BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift
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
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CaptureQueueManagerTests -only-testing:BookQuotesTests/CaptureQueueProcessingTests -only-testing:BookQuotesTests/CaptureQueueSupportTests -only-testing:BookQuotesTests/OnboardingSessionStateTests -only-testing:BookQuotesTests/OnboardingCompletionActionTests -only-testing:BookQuotesTests/OnboardingFlowPolicyTests
```

Initial result: blocked before compilation by the local Xcode runner:

```text
DVTFilePathFSEvents: Failed to start fs event stream.
Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = Error Domain=NSPOSIXErrorDomain Code=5 "Input/output error".
```

## Simulator Smoke Attempt

```sh
xcrun simctl list devices | head -30
```

Initial result: blocked because CoreSimulatorService was unavailable:

```text
Error Domain=NSPOSIXErrorDomain Code=61 "Connection refused"
Unable to lookup com.apple.CoreSimulator.CoreSimulatorService
```

## Residual Risk

- The manager dependency seam does not change extraction behaviour; model/OCR extraction remains covered by the extraction-specific issues.

## Retest After Runner Recovery

Focused onboarding/capture queue characterization gate:

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

Manual simulator smoke:

- `--uitesting --reset-onboarding --skip-auth`: app launched to onboarding welcome screen.
- `--uitesting --preload-library-test-data --mock-camera`: app launched to seeded Library with 3 books and 6 quotes.
- Screenshots:
  - `docs/refactor-foundation/verification/screenshots/2026-07-01-onboarding-reset-smoke.png`
  - `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`
