# Issue 035: Onboarding Session and Capture Queue Retry Scheduler Refactor

Status: closed

## Problem

`OnboardingView` was below the 500 LOC target, but it still owned mutable route/session state directly: current step, signed-in user, and completion progress. `CaptureQueueManager` was also below target, but still owned retry-task storage, replacement, and cancellation inline.

These are small state machines on user-visible paths. Keeping them inside the SwiftUI view and queue actor makes future onboarding and offline queue changes harder to characterize precisely.

## Acceptance Criteria

- Characterize onboarding session state before production edits.
- Characterize capture queue retry task bookkeeping before production edits.
- Preserve onboarding initial-step behavior from `OnboardingFlowPolicy`.
- Preserve signed-in-user storage when sign-in succeeds.
- Preserve post-sign-in routing through `OnboardingFlowPolicy`.
- Preserve completion progress state when onboarding completes.
- Preserve retry scheduling replacement behavior: scheduling a retry for the same item cancels the previous task.
- Preserve per-item retry cancellation.
- Preserve all-pending-retry cancellation on queue manager stop.
- Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- Run focused red-green tests for the extracted modules.
- Run nearby onboarding and capture queue characterization tests.
- Run simulator build.
- Attempt onboarding simulator UI smoke and record runner result.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`.
- Added `BookQuotes/Services/CaptureQueueRetryScheduler.swift`.
- Added `OnboardingSessionStateTests`.
- Added `CaptureQueueRetrySchedulerTests`.
- `OnboardingView` now delegates route/session mutation to `OnboardingSessionState`.
- `CaptureQueueManager` now delegates retry task storage, replacement, and cancellation to `CaptureQueueRetryScheduler`.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 162 LOC -> 160 LOC.
- `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`: 30 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 307 LOC -> 298 LOC.
- `BookQuotes/Services/CaptureQueueRetryScheduler.swift`: 30 LOC.

## Verification

- Focused red test confirmed missing production modules before implementation.
- Focused green tests passed:
  - `BookQuotesTests/OnboardingSessionStateTests`
  - `BookQuotesTests/CaptureQueueRetrySchedulerTests`
- Nearby characterization passed:
  - `BookQuotesTests/OnboardingFlowPolicyTests`
  - `BookQuotesTests/OnboardingCompletionStoreTests`
  - `BookQuotesTests/OnboardingAuthSkipPolicyTests`
  - `BookQuotesTests/OnboardingSessionStateTests`
  - `BookQuotesTests/CaptureQueueProcessingPreferencesTests`
  - `BookQuotesTests/CaptureQueueRetrySchedulerTests`
  - `BookQuotesTests/CaptureQueueSupportTests`
  - `BookQuotesTests/CaptureQueueStoreTests`
  - `BookQuotesTests/CaptureQueueManagerTests`
- Simulator build passed.
- Onboarding UI smoke attempted but failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- Onboarding UI behaviour remains covered by existing UI tests, but this runner could not initialize UI testing.
- `CaptureQueueManager` still owns network polling and processing task lifecycle. A future slice should only change that after a controllable network/clock seam is characterized.
