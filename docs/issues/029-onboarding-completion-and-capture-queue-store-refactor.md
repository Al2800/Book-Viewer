# Issue 029: Onboarding Completion and Capture Queue Store Refactor

Status: closed

## Problem

`OnboardingView` still directly wrote completion flags to `UserDefaults`, and `CaptureQueueManager` still mixed queue orchestration with SwiftData/file-backed queue mutations.

Both files were under 500 LOC, but the remaining complexity reduced locality for future onboarding and offline queue changes.

## Acceptance Criteria

- Characterize onboarding and queue behavior before production edits.
- Add a testable onboarding completion persistence module.
- Add a queue store module for enqueue, remove, retry, cancel, cleanup, stats, and next-pending-item lookup.
- Preserve onboarding completion flags: `hasCompletedOnboarding` and `showFirstCaptureCoaching`.
- Preserve queue item image storage, thumbnail generation, priority, status mutation, stats, and manager orchestration behavior.
- Keep `OnboardingView` focused on flow coordination, legal sheet presentation, haptics, callbacks, and dismissal.
- Keep `CaptureQueueManager` focused on lifecycle, network observation, processing orchestration, retry scheduling, and stats publication.
- Keep all touched files under 500 LOC.
- Run focused unit tests, wider queue/onboarding characterization, simulator build, and onboarding UI smoke attempt.

## Result

- Added `OnboardingCompletionStore`.
- Added `CaptureQueueStore`.
- Added `OnboardingCompletionStoreTests`.
- Added `CaptureQueueStoreTests`.
- `CaptureQueueManager` reduced from 378 LOC to 305 LOC.
