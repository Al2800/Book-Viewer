# Issue 066: Capture Queue Retry Coordinator Refactor

Status: `closed`

## Context

`CaptureQueueManager` should remain the actor that owns queue lifecycle and retry decisions, but it should not also own the mechanics of building, storing, replacing, and cancelling delayed retry tasks.

Issue 065 introduced retry characterization through the manager with an injected short retry policy. The next seam is the delayed retry task itself, because cancellation behavior should be testable without sleeping for the production backoff window.

## Acceptance Criteria

- [x] Characterize delayed retry scheduling before delegating manager logic.
- [x] Characterize cancelled scheduled retry behavior without relying on production backoff timing.
- [x] Keep `CaptureQueueManager` responsible for retry decisions and item reprocessing.
- [x] Move delayed retry task creation/storage/cancellation behind a small coordinator.
- [x] Preserve the production `.standard` retry policy.
- [x] Keep `CaptureQueueManager.swift` below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused queue tests when the local Xcode runner is healthy.
- [x] Run simulator capture-queue smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Services/CaptureQueueRetryCoordinator.swift`.
- Added `BookQuotesTests/Unit/Services/CaptureQueueRetryCoordinatorTests.swift`.
- `CaptureQueueRetryCoordinator` owns delayed retry task creation, sleep injection, task replacement, single-item cancellation, and cancel-all behavior.
- `CaptureQueueManager` now delegates scheduled retry mechanics to the coordinator while keeping:
  - processing start policy checks,
  - retryability checks through the queue store,
  - item reprocessing.

## Residual Risk / Next Slice

- `CaptureQueueManager` still coordinates public queue commands and stats publication. Further changes should be driven by manager-level tests, not coordinator tests.
- A broader controllable-clock abstraction is unnecessary until more queue timing behavior appears.

## Verification

- Focused onboarding/capture queue characterization gate on 2026-07-01:
  - 84 tests executed.
  - 0 failures.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual seeded/mock-camera simulator smoke:
  - App launched with `--uitesting --preload-library-test-data --mock-camera`.
  - Screenshot showed seeded Library data with 3 books and 6 quotes.
