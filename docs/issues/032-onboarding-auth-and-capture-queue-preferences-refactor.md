# Issue 032: Onboarding Auth and Capture Queue Preferences Refactor

Status: closed

## Problem

`OnboardingView` was below the 500 LOC target, but it still directly embedded simulator/UI-test auth skip rules. `CaptureQueueManager` was also below target, but it still directly knew the `autoProcessQueue` UserDefaults key and defaulting behavior.

Both decisions are small but load-bearing. They affect simulator behavior, TestFlight/auth routing, and offline capture queue processing. Keeping them inside view/actor code makes future behavior changes harder to characterize.

## Acceptance Criteria

- Characterize auth skip behavior before changing `OnboardingView`.
- Characterize auto-process queue preference behavior before changing `CaptureQueueManager`.
- Preserve simulator manual auth skip behavior.
- Preserve simulator auto-skip outside UI testing and no auto-skip during UI testing.
- Preserve device/manual auth skip behavior via `--skip-auth`.
- Preserve queue auto-processing default: enabled when unset.
- Preserve queue auto-processing stored setting behavior for true and false.
- Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- Add focused tests for the extracted modules.
- Run nearby onboarding/queue characterization tests.
- Run simulator build.
- Attempt onboarding simulator UI smoke and record result.
- Update architecture and refactor-foundation docs.

## Result

- Added `Features/Onboarding/OnboardingAuthSkipPolicy.swift`.
- Added `Services/CaptureQueueProcessingPreferences.swift`.
- Added `OnboardingAuthSkipPolicyTests`.
- Added `CaptureQueueProcessingPreferencesTests`.
- `OnboardingView` now asks a policy for manual/automatic auth skip behavior.
- `CaptureQueueManager` now asks a preferences module whether automatic queue processing is enabled.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 167 LOC -> 162 LOC.
- `BookQuotes/Features/Onboarding/OnboardingAuthSkipPolicy.swift`: 29 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 305 LOC -> 307 LOC.
- `BookQuotes/Services/CaptureQueueProcessingPreferences.swift`: 19 LOC.

## Verification

- Focused red test confirmed missing production module before implementation.
- Focused green tests passed:
  - `BookQuotesTests/OnboardingAuthSkipPolicyTests`
  - `BookQuotesTests/CaptureQueueProcessingPreferencesTests`
- Nearby characterization passed:
  - `BookQuotesTests/OnboardingAuthSkipPolicyTests`
  - `BookQuotesTests/OnboardingFlowPolicyTests`
  - `BookQuotesTests/OnboardingCompletionStoreTests`
  - `BookQuotesTests/CaptureQueueProcessingPreferencesTests`
  - `BookQuotesTests/CaptureQueueSupportTests`
  - `BookQuotesTests/CaptureQueueStoreTests`
  - `BookQuotesTests/CaptureQueueManagerTests`
- Simulator build passed.
- Onboarding UI smoke attempted but failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- UI behavior remains covered by existing `OnboardingFlowTests`, but this environment could not run them due the AX bootstrap timeout.
- Retry task storage/replacement/cancellation was extracted in issue `035`.
- `CaptureQueueManager` still owns delayed retry timing and network polling. A future slice should characterize those with a controllable clock/network seam before extracting that behavior.
