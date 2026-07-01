# Onboarding and Capture Queue Characterization Surface Refactor

## Characterized Behaviour

- `CaptureQueueItem` owns queue item state transitions, retry eligibility, and fetch descriptors.
- `QueueStats` owns active-count and status-description presentation.
- `QueueError` owns user-facing queue error descriptions.
- `CaptureQueueManager` owns actor lifecycle, stats publication, network injection, and public queue commands.
- `OnboardingView` owns SwiftUI coordination and delegates policy/state decisions to existing onboarding seams.

## Refactor Decision

No new production seam was added in this slice.

The deletion test failed for a new onboarding or queue lifecycle helper: the current code already has deep seams for policy, state, storage, processing, retry, network transition, and observation. Adding another wrapper around the remaining root files would have mostly moved one-line calls into a shallow module.

The useful seam improvement was the test surface:

- model behavior moved to `CaptureQueueItemTests`;
- queue support value behavior moved to `CaptureQueueSupportTests`;
- manager tests now focus on manager orchestration.

## Regression Coverage

- `CaptureQueueItemTests` now characterizes initial state, processing, failure retry count, max retry, reset for retry, cancellation, retry eligibility, and pending/failed descriptors.
- `CaptureQueueSupportTests` now characterizes queue stats, retry policy, processing start policy, stats builder aggregation, and queue errors.
- Existing onboarding tests remain the characterization route for onboarding route, auth skip, session, and completion behavior.

## Acceptance Notes

- `OnboardingView.swift`, `CaptureQueueManager.swift`, and `CaptureQueueManagerTests.swift` are all below 500 LOC after this slice.
- Simulator and `xcodebuild` verification are blocked by the local Xcode/CoreSimulator cache error until the environment recovers.
