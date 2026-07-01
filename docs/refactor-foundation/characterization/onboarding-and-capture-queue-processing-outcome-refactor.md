# Onboarding and Capture Queue Processing Outcome Refactor

## Characterized Behaviour

- `OnboardingView` remains a SwiftUI coordinator. Existing seams already characterize route policy, session state, auth skip policy, completion persistence, and step presentation.
- `CaptureQueueManager` remains the queue lifecycle actor.
- `CaptureQueueProcessingOutcome` now characterizes whether a processing result should request retry scheduling.

## Red-Green Notes

Added focused characterization for:

- retryable failed processing outcome returns a retry request with item id and retry count;
- non-retryable failed processing outcome does not request retry scheduling;
- completed and missing processing outcomes do not request retry scheduling.

The production change is deliberately small: retry eligibility is now local to the processing outcome interface, while the actor still owns the scheduling side effect.

## Refactor Decision

No new onboarding module was added. The deletion test failed for another onboarding root helper because the existing route, auth, session, completion, and step-view modules already concentrate the behaviour.

The queue extraction is a narrow deepening: callers no longer need to know the enum case pattern that means "schedule a retry"; they ask for a `CaptureQueueRetryRequest`.

## Regression Coverage

- `CaptureQueueProcessingTests`
- Existing `CaptureQueueManagerTests`
- Existing onboarding policy/session/completion tests

## Acceptance Notes

- This preserves the existing queue processing lifecycle.
- The simulator and full Xcode test runner still need local environment recovery before UI smoke can be completed.
