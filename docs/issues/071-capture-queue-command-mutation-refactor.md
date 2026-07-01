# Issue 071: Capture Queue Command Mutation Refactor

Status: `closed`

## Context

`OnboardingView.swift` is now a thin 148 LOC route shell: it owns injected services, legal-sheet presentation, session transitions, completion side effects, and the top-level background. The remaining useful characterization for this slice is around `CaptureQueueManager`, which still owns public queue commands.

`CaptureQueueManager.swift` was already below the 500 LOC target, but queue commands repeated the same pattern:

- mutate queue storage;
- update published queue stats;
- optionally start processing for queueing or retry commands.

Pending retry cancellation also needs manager-level characterization because it is user-visible behaviour: removed items must not be processed after a delayed retry fires.

## Acceptance Criteria

- [x] Confirm `OnboardingView.swift` remains below 500 LOC and does not absorb new queue behavior.
- [x] Characterize that `removeFromQueue(itemId:)` cancels pending retry work for that item.
- [x] Characterize that `retryItem(itemId:)` marks an item for retry and starts processing when online.
- [x] Preserve public `CaptureQueueManager` APIs.
- [x] Preserve standard production retry delays.
- [x] Extract repeated queue command mutation/stat/start orchestration into one manager helper.
- [x] Keep `CaptureQueueManager.swift` below 500 LOC.
- [x] Update architecture and verification docs.
- [x] Run focused manager tests when the local Xcode runner is healthy.
- [x] Run simulator queue smoke when CoreSimulatorService is available.

## Implementation

- Added `CaptureQueueManagerTests.testRemoveFromQueueCancelsPendingRetryForItem`.
- Added `CaptureQueueManagerTests.testRetryItemMarksItemForRetryAndProcessesWhenOnline`.
- Extended the manager test store spy to observe removed and retried item IDs.
- Added `CaptureQueueManager.performQueueMutation(startReason:_:)`.
- Routed `addToQueue`, `removeFromQueue`, `retryItem`, `cancelItem`, and `cleanupOldItems` through the shared queue mutation helper.

## Verification

- `git diff --check` passed.
- `plutil -lint BookQuotes.xcodeproj/project.pbxproj` passed.
- LOC check:
  - `BookQuotes/Features/Onboarding/OnboardingView.swift`: 148 LOC.
  - `BookQuotes/Services/CaptureQueueManager.swift`: 303 LOC.
  - `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`: 416 LOC.
- Focused onboarding/capture queue characterization gate on 2026-07-01:
  - 84 tests executed.
  - 0 failures.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.

## Follow-Up

- Further manager changes should keep using public manager APIs with fake `CaptureQueueStoring` and `CaptureQueueItemProcessing` adapters.
