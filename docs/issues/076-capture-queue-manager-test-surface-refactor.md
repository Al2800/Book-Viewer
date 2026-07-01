# Issue 076: Capture Queue Manager Test Surface Refactor

Status: `closed`

## Context

`CaptureQueueManagerTests.swift` had grown into the largest file in the onboarding/capture-queue area. It mixed manager behavior tests with reusable fake network, storage, processor, and retry-wait helpers.

The production manager remains below 500 LOC. The useful refactor pressure here is characterization depth and keeping future queue tests easy to add without making the main manager test file harder to scan.

## Acceptance Criteria

- [x] Add a missing manager-level characterization before refactoring the test surface.
- [x] Preserve existing public `CaptureQueueManager` APIs.
- [x] Preserve existing queue manager test behavior.
- [x] Extract reusable queue manager test doubles into a focused test-support file.
- [x] Keep `CaptureQueueManagerTests.swift` below 500 LOC with more room for future characterization.
- [x] Keep production files unchanged unless behavior requires it.
- [x] Update issue, characterization, architecture, and verification docs.
- [x] Run focused queue manager tests when the local Xcode runner is healthy.
- [x] Run simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `CaptureQueueManagerTests.testStatsPublisherUsesProcessingFallbackWhenStatsReadFails`.
- Extended `SpyCaptureQueueStore` to simulate stats-read failure.
- Added `CaptureQueueManagerTestDoubles.swift`.
- Moved `StubCaptureQueueNetworkMonitor`, `SpyCaptureQueueStore`, `SpyCaptureQueueItemProcessor`, and `waitForProcessedItemCount` into the new test-support file.
- Left production queue manager code unchanged.

## Verification

- See `docs/refactor-foundation/verification/2026-07-01-capture-queue-manager-test-surface-refactor.md`.

Additional verification on 2026-07-01:

- Focused onboarding/capture queue characterization gate passed:
  - 84 tests executed.
  - 0 failures.
- Broad unit gate passed:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke passed:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
  - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

## Follow-Up

- Future manager orchestration tests should reuse `CaptureQueueManagerTestDoubles.swift`.
- If the test-support file grows toward 500 LOC, split by role: network monitor, queue store, item processor, and async wait helpers.
