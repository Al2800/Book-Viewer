# Onboarding and Capture Queue Refactor - 2026-06-14

## Scope

- Extracted welcome carousel data/presentation from `OnboardingView.swift` into `Features/Onboarding/OnboardingWelcomeViews.swift`.
- Extracted marking setup controls into `Features/Onboarding/OnboardingMarkingViews.swift`.
- Extracted embedded onboarding paywall and media plan card UI into `Features/Onboarding/OnboardingPaywallViews.swift`.
- Extracted queue stats/errors from `CaptureQueueManager.swift` into `Services/CaptureQueueTypes.swift`.
- Extracted shared queue manager initialization into `Services/CaptureQueueShared.swift`.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 774 LOC -> 384 LOC.
- `BookQuotes/Features/Onboarding/OnboardingWelcomeViews.swift`: 67 LOC.
- `BookQuotes/Features/Onboarding/OnboardingMarkingViews.swift`: 51 LOC.
- `BookQuotes/Features/Onboarding/OnboardingPaywallViews.swift`: 273 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 568 LOC -> 475 LOC.
- `BookQuotes/Services/CaptureQueueTypes.swift`: 66 LOC.
- `BookQuotes/Services/CaptureQueueShared.swift`: 23 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Queue unit/integration characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result before edits:

- Passed.
- Runtime: `10.587` seconds.

Result after refactor:

- Passed.
- Runtime: `5.713` seconds.

Onboarding simulator UI characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests
```

Result before edits:

- Passed.
- Runtime: `124.777` seconds.

Result after refactor:

- Passed.
- Runtime: `125.909` seconds.

Notes:

- Xcode emitted existing Swift 6 sendability, availability, and simulator debugger warnings.
- No tests were changed to make this pass.

## Residual Risk

- `CaptureQueueManager` still owns processing and retry orchestration; a deeper extraction should be guarded by specific processing/retry/offline transition characterization.
- `OnboardingPaywallViews` is cohesive but still sizeable because it owns product selection, media-plan fallback display, purchase action, and error presentation.
