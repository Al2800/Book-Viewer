# Onboarding and Capture Queue Manager Dependencies Characterization

## Scope

This slice reviewed `OnboardingView.swift` and `CaptureQueueManager.swift` after the earlier modular refactors.

## Current Behaviour Characterized

- Onboarding route decisions are already covered by `OnboardingFlowPolicyTests`.
- Onboarding mutable step/session behaviour is already covered by `OnboardingSessionStateTests`.
- Onboarding completion persistence sequencing is already covered by `OnboardingCompletionActionTests` and `OnboardingCompletionStoreTests`.
- `OnboardingView` now only coordinates the active step, injected services, legal sheet, completion callback, haptic, and dismissal.
- `CaptureQueueManager` remains the actor that owns processing lifecycle and stats publication.
- Manual queue processing should process the next pending item when the queue is online.
- Manual queue processing should not process pending items when the queue is offline.
- Processing should publish active stats while work is running, then idle stats when the processing loop finishes.

## Missing Test Surface Before This Slice

`CaptureQueueManagerTests` could verify lifecycle commands and stats publication, but manager-level processing tests still needed the live SwiftData store and item processor. That made it difficult to characterize actor orchestration without invoking image storage, model extraction, or real queue transactions.

## Refactor Decision

Add a dependency seam for the two collaborators the manager orchestrates:

- `CaptureQueueStoring`: queue mutations, stats reads, and next-pending lookup.
- `CaptureQueueItemProcessing`: single-item processing outcome.

The existing app initializer still builds the live `CaptureQueueStore` and `CaptureQueueItemProcessor`. Tests can now inject fake adapters and verify manager behaviour through the manager interface.

## Acceptance Coverage Added

- `CaptureQueueManagerTests.testProcessNowProcessesNextPendingItemWhenOnline`
- `CaptureQueueManagerTests.testProcessNowDoesNotProcessWhenOffline`

## Non-Goals

- No onboarding production extraction in this slice.
- No retry timing change.
- No extraction/model behaviour change.
- No SwiftData queue transaction change.
