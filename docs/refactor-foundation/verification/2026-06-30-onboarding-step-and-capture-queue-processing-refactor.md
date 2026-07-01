# Onboarding Step and Capture Queue Processing Refactor - 2026-06-30

## Scope

- Extracted onboarding step screen composition from `Features/Onboarding/OnboardingView.swift` into `Features/Onboarding/OnboardingStepViews.swift`.
- Kept onboarding root coordination, legal sheet presentation, service injection, and completion side effects in `OnboardingView.swift`.
- Extracted queued item processing from `Services/CaptureQueueManager.swift` into `Services/CaptureQueueProcessing.swift`.
- Kept queue lifecycle, stats publication, network observation, and retry scheduling in `CaptureQueueManager.swift`.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 384 LOC -> 154 LOC.
- `BookQuotes/Features/Onboarding/OnboardingStepViews.swift`: 255 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 475 LOC -> 416 LOC.
- `BookQuotes/Services/CaptureQueueProcessing.swift`: 91 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed after onboarding extraction.
- Passed after capture queue processing extraction.

Queue unit/integration characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result before edits:

- Passed.
- Runtime: `30.783` seconds.

Result after refactor:

- Passed.
- Runtime: `31.809` seconds.

Onboarding simulator UI characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests
```

Result before edits:

- Failed before app assertions.
- XCTest UI runner error: `Timed out waiting for AX loaded notification`.
- Runtime before failure: `100.317` seconds.

Result after refactor:

- Failed before app assertions with the same XCTest UI runner error.
- Runtime before failure: `99.777` seconds.

Notes:

- A first attempt to run queue and onboarding tests in parallel failed because Xcode locked the shared DerivedData build database. Subsequent runs were sequential.
- Xcode emitted existing Swift 6 sendability, availability, and simulator framework copy warnings.
- No tests were edited for this slice.

## Residual Risk

- The onboarding route still needs a passing simulator UI smoke once the local AX runner issue is cleared.
- `CaptureQueueProcessing` preserves the concrete extraction path but still lacks a protocol seam for hermetic success/failure processing tests.
- Further queue behaviour changes should first introduce a testable extraction dependency and characterize retry outcomes with a fake extractor.
