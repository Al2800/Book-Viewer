# Onboarding Session and Capture Queue Retry Scheduler Refactor Characterization

Date: 2026-06-30

## Scope

This slice characterized two remaining mutable state seams:

- onboarding route/session state: current step, signed-in user, and completion progress;
- capture queue retry bookkeeping: retry task replacement, per-item cancellation, and full cancellation on stop.

The intent was not to alter onboarding flow or offline queue processing. It was to make the small state machines explicit and testable.

## Characterized Behavior

- Onboarding starts at `OnboardingFlowPolicy.initialStep`.
- Signing in stores the returned `User`.
- Continuing after sign-in routes to `OnboardingFlowPolicy.stepAfterSignIn`.
- Completing onboarding marks completion as in progress before persistence/haptics/dismissal side effects run.
- Scheduling a retry for an item cancels any existing retry task for that same item.
- Cancelling a retry removes that item from the pending retry registry.
- Cancelling all retries cancels every pending retry task and clears the registry.

## Red Step

Added `OnboardingSessionStateTests` and `CaptureQueueRetrySchedulerTests`.

The first focused run failed because `OnboardingSessionState` and `CaptureQueueRetryScheduler` did not exist, confirming the tests were exercising missing production seams.

## Refactor

- Added `OnboardingSessionState` as the small state module behind `OnboardingView`.
- Added `CaptureQueueRetryScheduler` as the retry-task registry behind `CaptureQueueManager`.
- Kept SwiftUI animation, completion persistence, haptics, dismissal, network checks, retry delays, and queue processing orchestration in their existing owners.

## Verification

See `docs/refactor-foundation/verification/2026-06-30-onboarding-session-and-capture-queue-retry-scheduler-refactor.md`.
