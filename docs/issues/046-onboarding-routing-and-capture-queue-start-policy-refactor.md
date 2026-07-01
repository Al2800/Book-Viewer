# Issue 046: Onboarding Routing and Capture Queue Start Policy Refactor

Status: closed

## Context

`OnboardingView` and `CaptureQueueManager` were already below the 500 LOC target, but both still embedded small user-visible decisions:

- `OnboardingView` directly chose the next step for welcome, subscription, and marking setup callbacks.
- `CaptureQueueManager` directly mixed network state and auto-processing preference checks across manager start, item enqueue, manual process, manual retry, and retry-delay paths.

These decisions are small, but they are foundation code. Future onboarding and offline queue changes should alter characterized route/start-policy seams, not scatter conditional changes through SwiftUI or actor orchestration.

## Acceptance Criteria

- Characterize fixed onboarding route advances before production edits.
- Characterize queue start policy before production edits.
- Preserve onboarding flow:
  - welcome skip/complete advances to sign-in.
  - sign-in continues according to `OnboardingFlowPolicy`.
  - subscription advances to marking setup.
  - marking setup advances to complete.
- Preserve queue start behavior:
  - manager start and queued-item triggers require online state and auto-processing enabled.
  - manual process, manual retry, and retry-delay triggers require online state only.
- Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- Run focused and nearby onboarding/queue tests.
- Run simulator build and attempt simulator smoke.

## Implementation

- Added fixed step advance methods to `OnboardingSessionState`.
- Updated `OnboardingView` to call session-state route methods instead of embedding target steps in callbacks.
- Added `CaptureQueueProcessingStartReason` and `CaptureQueueProcessingStartPolicy` to `CaptureQueueSupport`.
- Updated `CaptureQueueManager` to ask the start policy before automatic/manual processing triggers.

## LOC Impact

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 170 LOC.
- `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`: 42 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 289 LOC.
- `BookQuotes/Services/CaptureQueueSupport.swift`: 88 LOC.

## Verification

- Focused RED confirmed missing route/start-policy seams.
- Focused GREEN passed:
  - `BookQuotesTests/OnboardingSessionStateTests`
  - `BookQuotesTests/CaptureQueueSupportTests`
- Nearby onboarding/queue characterization passed:
  - `BookQuotesTests/OnboardingFlowPolicyTests`
  - `BookQuotesTests/OnboardingAuthSkipPolicyTests`
  - `BookQuotesTests/OnboardingSessionStateTests`
  - `BookQuotesTests/OnboardingCompletionActionTests`
  - `BookQuotesTests/OnboardingCompletionStoreTests`
  - `BookQuotesTests/CaptureQueueSupportTests`
  - `BookQuotesTests/CaptureQueueProcessingPreferencesTests`
  - `BookQuotesTests/CaptureQueueRetrySchedulerTests`
  - `BookQuotesTests/CaptureQueueNetworkTransitionTests`
  - `BookQuotesTests/CaptureQueueNetworkObserverTests`
  - `BookQuotesTests/CaptureQueueStoreTests`
  - `BookQuotesTests/CaptureQueueManagerTests`

## Follow-Up

- `CaptureQueueManager` still owns processing task lifecycle and retry task creation. Keep it there unless future behavior changes need a controllable clock/task seam.
- Any change to queue trigger rules should start in `CaptureQueueSupportTests`.
