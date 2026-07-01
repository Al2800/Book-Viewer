# Onboarding Step and Capture Queue Retry Characterization

Date: 2026-07-01

Issue: `065-onboarding-step-and-capture-queue-retry-characterization.md`

## Scope

This slice targets ownership/testability, not visible behavior.

- `OnboardingView` should remain the SwiftUI step coordinator.
- `OnboardingStep` should be domain state used by onboarding policy/session modules, not a nested view type.
- `CaptureQueueManager` should remain responsible for actor-owned processing and retry orchestration.
- Retry behavior should be characterizable without waiting for the production backoff delays.

## Characterized Behavior

Existing onboarding tests already characterize the public state transitions:

- `OnboardingFlowPolicyTests` covers initial step routing and post-sign-in routing.
- `OnboardingSessionStateTests` covers welcome, sign-in, subscription, marking setup, explicit step advancement, signed-in user retention, and completion progress.
- `OnboardingCompletionActionTests` covers completion state plus persisted onboarding/coaching flags.

New queue manager characterization:

- `testRetryableFailureReprocessesItemAfterRetryDelayWhenStillRetryable`
  - drives the public `processNow()` API,
  - returns a retryable failure from the injected item processor,
  - uses a zero-delay retry policy,
  - confirms the same item is processed a second time only after the store says it can still retry.

## Non-Goals

- No onboarding UI copy/layout changes.
- No queue processing transaction changes.
- No model extraction, OCR, or quote parsing changes.
- No new scheduler abstraction unless retry cancellation/timing needs further characterization.
