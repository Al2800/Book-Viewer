# Issue 065: Onboarding Step and Capture Queue Retry Characterization

Status: `closed`

## Context

`OnboardingView.swift` and `CaptureQueueManager.swift` are already below the 500 LOC target, so this slice should not create broad new presentation modules.

The remaining useful pressure is ownership and testability:

- The onboarding step type was owned by `OnboardingView`, even though route policy and session state use it as domain state.
- `CaptureQueueManager` owns retry orchestration, but the standard backoff delay made retry behavior hard to characterize through the public manager API.

## Acceptance Criteria

- [x] Characterize onboarding route/session behavior before moving step ownership.
- [x] Move onboarding step ownership out of `OnboardingView` without changing the visible flow.
- [x] Keep `OnboardingView.swift` below 500 LOC.
- [x] Characterize queue retry orchestration through `CaptureQueueManager.processNow()`.
- [x] Preserve the standard production retry delays.
- [x] Allow tests to inject a zero-delay retry policy without changing app-facing initialization.
- [x] Keep `CaptureQueueManager.swift` below 500 LOC.
- [x] Update architecture and verification docs.
- [x] Run focused onboarding and queue tests when the local Xcode runner is healthy.
- [x] Run simulator onboarding/capture-queue smoke when CoreSimulatorService is available.

## Implementation

- Moved `OnboardingStep` out of `OnboardingView` and into the onboarding state layer.
- Updated `OnboardingFlowPolicy` and `OnboardingSessionState` to use the standalone `OnboardingStep`.
- Added `CaptureQueueRetryPolicy.standard` for the live backoff configuration.
- Injected `CaptureQueueRetryPolicy` into `CaptureQueueManager`, defaulting to `.standard`.
- Added a manager-level characterization proving a retryable failed processing outcome reprocesses the same item after the configured retry delay when the store still reports it as retryable.

## Follow-Up

- Issue 066 extracts delayed retry task mechanics into `CaptureQueueRetryCoordinator` with controlled-sleep characterization for scheduling and cancellation.
- Issue 071 characterizes public queue command mutation paths and pending retry cancellation through `CaptureQueueManager`.
- Onboarding view changes should continue through route/session/completion tests before touching `OnboardingView`.

## Verification

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
