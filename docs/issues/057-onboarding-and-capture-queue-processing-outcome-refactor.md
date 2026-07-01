# Issue 057: Onboarding and Capture Queue Processing Outcome Refactor

Status: `closed`

## Context

`OnboardingView.swift` and `CaptureQueueManager.swift` are already below the 500 LOC target after the earlier onboarding/capture queue slices.

The remaining useful refactor pressure in this area is precision, not another broad extraction:

- `OnboardingView` should stay as the SwiftUI coordinator and continue delegating route, auth skip, session, and completion decisions to existing onboarding seams.
- `CaptureQueueManager` should stay as the actor for lifecycle, network observation, processing orchestration, retry scheduling, and stats publication.
- Retry scheduling after processing was still matched directly inside the actor from `CaptureQueueProcessingOutcome`.

## Acceptance Criteria

- Characterize processing outcomes before changing actor retry scheduling.
- Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- Do not add an onboarding production module unless it passes the deletion test.
- Move retry-scheduling eligibility behind the processing outcome interface.
- Keep the actor responsible for actually scheduling retry tasks.
- Add focused unit coverage for retryable failure, non-retryable failure, completed outcome, and missing outcome.
- Register new tests in the Xcode project.
- Attempt focused tests and simulator smoke, recording any local Xcode/CoreSimulator blocker.
- Update architecture and verification docs.

## Implementation

- Added `BookQuotesTests/Unit/Services/CaptureQueueProcessingTests.swift`.
- Added `CaptureQueueProcessingOutcome.retryRequest`.
- Added `CaptureQueueRetryRequest`.
- Updated `CaptureQueueManager.processItem(itemID:)` to ask the outcome for a retry request instead of matching retryable failures inline.
- Left `OnboardingView` unchanged because its remaining code is SwiftUI coordination and existing onboarding seams already own the deterministic behaviour.

## LOC Impact

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: remains 160 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: 281 LOC.
- `BookQuotes/Services/CaptureQueueProcessing.swift`: 104 LOC.
- `BookQuotesTests/Unit/Services/CaptureQueueProcessingTests.swift`: 34 LOC.

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
  - Manual seeded/mock-camera simulator smoke:
    - App launched with `--uitesting --preload-library-test-data --mock-camera`.
    - Screenshot showed seeded Library data with 3 books and 6 quotes.

## Follow-Up

- Further onboarding changes should start in `OnboardingFlowPolicyTests`, `OnboardingSessionStateTests`, `OnboardingCompletionActionTests`, or the relevant step view module before touching `OnboardingView`.
- Further queue retry timing changes should stay in `CaptureQueueRetryPolicy` or `CaptureQueueRetryScheduler`.
- Further queue processing transaction changes should first add a testable extraction dependency before changing the live model extraction path.
