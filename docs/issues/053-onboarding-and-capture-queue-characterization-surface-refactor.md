# Issue 053: Onboarding and Capture Queue Characterization Surface Refactor

Status: closed

## Context

`OnboardingView.swift` and `CaptureQueueManager.swift` are already below the 500 LOC target and have meaningful seams for route policy, auth skip policy, completion persistence, queue storage, processing, retry scheduling, network monitoring, and start policy.

The remaining friction was not a large production file. It was the characterization surface:

- `CaptureQueueManagerTests.swift` had grown above 500 LOC and mixed manager lifecycle checks with queue item, queue stats, descriptor, and queue error behavior.
- `OnboardingView.swift` and `CaptureQueueManager.swift` still had small passthrough helpers that did not add locality.

## Acceptance Criteria

- Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- Keep `CaptureQueueManagerTests.swift` below 500 LOC.
- Move queue item behavior characterization to `CaptureQueueItemTests`.
- Move queue stats and queue error characterization to `CaptureQueueSupportTests`.
- Keep manager tests focused on manager lifecycle, stats publication, network injection, and public manager commands.
- Remove shallow passthroughs only where behavior is already characterized by existing seams.
- Do not add new production modules unless the module passes the deletion test.
- Attempt focused onboarding/queue tests and record any Xcode/simulator blocker.

## Implementation

- Moved `CaptureQueueItem` initial state, status transition, retry, cancel, retry eligibility, and descriptor tests out of `CaptureQueueManagerTests` and into `CaptureQueueItemTests`.
- Moved `QueueStats` description/active-count tests and `QueueError` description tests out of `CaptureQueueManagerTests` and into `CaptureQueueSupportTests`.
- Kept `CaptureQueueManagerTests` focused on the actor-owned behavior it actually coordinates.
- Inlined auth-skip passthrough values in `OnboardingView`.
- Removed an unused `maxConcurrentTasks` constant and an auto-process passthrough in `CaptureQueueManager`.
- Avoided a new production seam because the current onboarding and queue seams already carry the relevant decisions.

## LOC Impact

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 170 LOC -> 160 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 289 LOC -> 282 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueManagerTests.swift`: 531 LOC -> 158 LOC.
- `BookQuotesTests/Unit/Models/CaptureQueueItemTests.swift`: 61 LOC -> 262 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueSupportTests.swift`: 101 LOC -> 193 LOC.

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

- Further production queue lifecycle changes should only happen with a controllable task/clock seam and focused characterization for cancellation, duplicate starts, and retry timing.
- Further onboarding changes should continue through `OnboardingFlowPolicy`, `OnboardingSessionState`, `OnboardingCompletionAction`, and the relevant step view modules before touching `OnboardingView`.
