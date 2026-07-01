# Issue 075: Capture Queue Stats Reporter Refactor

Status: `closed`

## Context

`OnboardingView.swift` is already a thin 148 LOC route shell. Its remaining responsibilities are injected service ownership, legal-sheet presentation, onboarding session transitions, completion side effects, haptics, callback, dismissal, and top-level background composition.

`CaptureQueueManager.swift` is below the 500 LOC target, but it still owned the Combine subject used by app UI to observe queue stats. That made the actor responsible for both queue orchestration and the mechanics of current-value stats publication.

## Acceptance Criteria

- [x] Characterize current queue stats publication before production edits.
- [x] Preserve public `CaptureQueueManager.stats`.
- [x] Preserve public `CaptureQueueManager.statsPublisher`.
- [x] Keep `OnboardingView.swift` unchanged unless a behaviour seam justifies editing it.
- [x] Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- [x] Move stats-subject mechanics behind a focused module.
- [x] Update architecture and verification docs.
- [x] Run focused stats/manager/onboarding tests when the local Xcode runner is healthy.
- [x] Run simulator onboarding/queue smoke when CoreSimulatorService is available.

## Implementation

- Added `CaptureQueueStatsReporter`.
- Added `CaptureQueueStatsReporterTests` for initial stats, current-value updates, and publisher emissions.
- Updated `CaptureQueueManager` to publish and expose stats through `CaptureQueueStatsReporter`.
- Left `OnboardingView` unchanged after characterization because existing onboarding modules already own deterministic route/session/auth/completion behavior.

## Verification

- See `docs/refactor-foundation/verification/2026-07-01-capture-queue-stats-reporter-refactor.md`.

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

## Follow-Up

- Further visible onboarding changes should start in the relevant state/policy/presentation tests before touching `OnboardingView`.
- Further queue UI badge/count changes should start in `CaptureQueueStatsReporterTests`, `CaptureQueueSupportTests`, and the public manager stats tests.
