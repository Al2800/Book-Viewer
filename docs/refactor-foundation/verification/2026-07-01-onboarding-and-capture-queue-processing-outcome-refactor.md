# Onboarding and Capture Queue Processing Outcome Refactor Verification

## Scope

- Added retry request characterization for `CaptureQueueProcessingOutcome`.
- Moved retryable-failure matching out of `CaptureQueueManager`.
- Left `OnboardingView` behaviour unchanged after reassessing the existing onboarding seams.

## LOC Snapshot

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 160 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 281 LOC.
- `BookQuotes/Services/CaptureQueueProcessing.swift`: 104 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueProcessingTests.swift`: 34 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`: 158 LOC.
- `BookQuotesTests/Unit/Utilities/OnboardingSessionStateTests.swift`: 89 LOC.

## Static Checks

```sh
git diff --check
plutil -lint BookQuotes.xcodeproj/project.pbxproj
wc -l BookQuotes/Features/Onboarding/OnboardingView.swift \
  BookQuotes/Services/CaptureQueueManager.swift \
  BookQuotes/Services/CaptureQueueProcessing.swift \
  BookQuotesTests/Unit/Services/CaptureQueueProcessingTests.swift \
  BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift \
  BookQuotesTests/Unit/Utilities/OnboardingSessionStateTests.swift
```

Result: passed.

## Focused Test Attempt

```sh
xcodebuild test -quiet \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueProcessingTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OnboardingSessionStateTests \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/OnboardingCompletionActionTests
```

Result: blocked before compilation by local Xcode cache/FSEvents failure:

- `DVTFilePathFSEvents: Failed to start fs event stream.`
- `Failed to get length of DARWIN_USER_CACHE_DIR from confstr(3), error = ... Code=5 "Input/output error".`

## Simulator Smoke

```sh
xcrun simctl list devices | head -30
```

Result: blocked. `simctl` cannot connect to `com.apple.CoreSimulator.CoreSimulatorService` and returns `NSPOSIXErrorDomain Code=61 "Connection refused"`.

## Residual Risk

- Queue extraction transaction success/failure still depends on the live `GeminiService` path and should not be deeply refactored until a testable extraction dependency is introduced.
- Local Xcode/CoreSimulator environment has recently failed before compilation, so simulator verification may remain blocked.
