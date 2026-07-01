# Characterization: Onboarding Routing and Capture Queue Start Policy Refactor

Date: 2026-07-01

## Scope

This slice characterized deterministic route and start-policy behavior before moving it out of direct view/actor conditionals.

## Onboarding Characterization

`OnboardingSessionStateTests` now pins:

- welcome advances to sign-in.
- subscription advances to marking setup.
- marking setup advances to complete.
- sign-in continues according to `OnboardingFlowPolicy`.
- signed-in user state survives explicit route changes.
- completion marks the session as completing.

## Capture Queue Characterization

`CaptureQueueSupportTests` now pins:

- manager start and item-queued starts require online state and auto-processing enabled.
- manual process, manual retry, and retry-delay starts require online state only.
- offline state blocks every start reason.

## Refactor Rule

`OnboardingView` remains the SwiftUI coordinator for animation, service injection, legal sheet presentation, haptics, callback, and dismissal. It should not own route target decisions.

`CaptureQueueManager` remains the actor for queue lifecycle and async orchestration. It should not own the pure start-trigger matrix.
