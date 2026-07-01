# 2026-07-01: Onboarding and Capture Queue Characterization Surface Refactor

## Changes

- Split pure queue item characterization out of `CaptureQueueManagerTests` into `CaptureQueueItemTests`.
- Split queue stats and queue error characterization out of `CaptureQueueManagerTests` into `CaptureQueueSupportTests`.
- Kept `CaptureQueueManagerTests` focused on manager lifecycle, network injection, stats publisher behavior, and public manager setup paths.
- Inlined shallow auth-skip passthroughs in `OnboardingView`.
- Removed an unused queue manager concurrency constant and an auto-process passthrough.

## LOC

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 160 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 282 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`: 158 LOC.
- `BookQuotesTests/Unit/Models/CaptureQueueItemTests.swift`: 262 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueSupportTests.swift`: 193 LOC.

## Static Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched onboarding, queue, and test files.

## Xcode Verification

Focused queue/onboarding tests:

```sh
xcodebuild test -quiet \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/CaptureQueueItemTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/OnboardingSessionStateTests \
  -only-testing:BookQuotesTests/OnboardingAuthSkipPolicyTests \
  -only-testing:BookQuotesTests/OnboardingCompletionActionTests \
  -only-testing:BookQuotesTests/OnboardingCompletionStoreTests
```

Initial attempt was blocked by local Xcode/CoreSimulator availability. Retried after the runner recovered.

Result: passed.

- 84 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-51-10-+0100.xcresult`.

## Simulator Smoke

```sh
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --reset-onboarding --skip-auth -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-onboarding-reset-smoke.png
```

Result: passed.

- App launched.
- Screenshot showed the onboarding welcome screen.

```sh
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --preload-library-test-data --mock-camera -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png
```

Result: passed.

- App launched.
- Screenshot showed seeded Library data with 3 books and 6 quotes.
