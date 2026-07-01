# Issue 061: Onboarding and Capture Queue Manager Dependencies Refactor

Status: `closed`

## Context

`OnboardingView.swift` and `CaptureQueueManager.swift` are already below the 500 LOC target. The useful pressure in this slice was characterization depth, not broad extraction.

`OnboardingView` is now a thin SwiftUI coordinator with route, auth skip, completion, and step presentation behaviour already held in smaller onboarding modules. No further onboarding production extraction passed the deletion test for this slice.

`CaptureQueueManager` still required real SwiftData storage and the live queue item processor for manager-level processing tests. That made it hard to characterize the actor-owned behaviours that should remain in the manager: manual processing, online/offline gating, and active/idle stats publication.

## Acceptance Criteria

- [x] Characterize the current onboarding and capture queue seams before production edits.
- [x] Keep `OnboardingView.swift` below 500 LOC.
- [x] Keep `CaptureQueueManager.swift` below 500 LOC.
- [x] Avoid new onboarding production modules unless they concentrate behaviour.
- [x] Add a capture queue dependency seam that keeps the existing app-facing manager initializer intact.
- [x] Keep `CaptureQueueManager` responsible for lifecycle, task orchestration, retry scheduling, and stats publication.
- [x] Add focused manager tests for manual processing when online.
- [x] Add focused manager tests for no processing when offline.
- [x] Register new production code in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused queue/onboarding tests when the local Xcode runner is healthy.
- [x] Run simulator smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Services/CaptureQueueDependencies.swift`.
- Added `CaptureQueueStoring` for the queue store operations that the manager orchestrates.
- Added `CaptureQueueItemProcessing` for processing one queued item.
- Made `CaptureQueueStore` and `CaptureQueueItemProcessor` the live adapters.
- Added an internal dependency-injection initializer to `CaptureQueueManager`.
- Added focused characterization tests to `CaptureQueueManagerTests` using fake store and processor adapters.
- Left `OnboardingView` unchanged because existing onboarding seams already own its deterministic behaviour.

## LOC Impact

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 160 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 281 LOC -> 295 LOC.
- `BookQuotes/Services/CaptureQueueDependencies.swift`: 28 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`: 258 LOC.

## Verification

- Passed:
  - `git diff --check`
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - LOC check for touched files.
  - Focused onboarding/capture queue characterization gate on 2026-07-01:
    - 84 tests executed.
    - 0 failures.
  - Broad unit gate on 2026-07-01:
    - 548 tests executed.
    - 0 failures.
  - Manual onboarding reset simulator smoke:
    - App launched with `--uitesting --reset-onboarding --skip-auth`.
    - Screenshot showed the onboarding welcome screen.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-onboarding-reset-smoke.png`.
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.
    - Artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-capture-queue-seeded-smoke.png`.

## Follow-Up

- Further onboarding changes should still start in `OnboardingFlowPolicyTests`, `OnboardingSessionStateTests`, `OnboardingCompletionActionTests`, or the relevant step view module before touching `OnboardingView`.
- Further manager-level queue tests can now use fake `CaptureQueueStoring` and `CaptureQueueItemProcessing` adapters for processing orchestration without invoking Gemini extraction.
- Issue 065 adds retry orchestration characterization through `CaptureQueueManager` with an injected short `CaptureQueueRetryPolicy`; deeper retry timing changes should still wait for a controllable clock/task seam.
