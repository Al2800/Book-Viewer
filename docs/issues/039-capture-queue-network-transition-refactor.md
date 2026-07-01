# Issue 039: Capture Queue Network Transition Refactor

Status: closed

## Problem

`CaptureQueueManager` had a restored-connection rule embedded directly inside its polling loop: when the previous network state was disconnected and the new state is connected, start processing only if automatic queue processing is enabled.

That rule is small, but it is user-visible offline queue behavior and should be testable without sleeping a task, starting `NWPathMonitor`, or waiting for real network changes.

## Acceptance Criteria

- Characterize restored-connection processing before production edits.
- Preserve processing start when the queue transitions from offline to online and auto-processing is enabled.
- Preserve no-start behavior when auto-processing is disabled.
- Preserve no-start behavior when the connection remains online.
- Preserve no-start behavior when the connection is lost.
- Keep `CaptureQueueManager.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby capture queue characterization tests.
- Run simulator build.
- Attempt onboarding simulator UI smoke and record runner result.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Services/CaptureQueueNetworkTransition.swift`.
- Added `BookQuotesTests/Unit/Services/CaptureQueueNetworkTransitionTests.swift`.
- Updated `CaptureQueueManager` network polling to delegate the restored-connection decision to `CaptureQueueNetworkTransition`.

## LOC Result

- `BookQuotes/Services/CaptureQueueManager.swift`: 298 LOC -> 301 LOC.
- `BookQuotes/Services/CaptureQueueNetworkTransition.swift`: 11 LOC.
- `BookQuotes/Services/CaptureQueueNetworkMonitoring.swift`: remains 10 LOC.

The manager remains below the 500 LOC target. The small increase is accepted because the transition rule now has a direct characterization test and a stable seam for later network restoration work.

## Verification

- Focused red test confirmed missing production module before implementation:
  - `BookQuotesTests/CaptureQueueNetworkTransitionTests`
- Focused green test passed:
  - `BookQuotesTests/CaptureQueueNetworkTransitionTests`
- Nearby queue characterization passed:
  - `BookQuotesTests/CaptureQueueNetworkTransitionTests`
  - `BookQuotesTests/CaptureQueueManagerTests`
  - `BookQuotesTests/CaptureQueueProcessingPreferencesTests`
  - `BookQuotesTests/CaptureQueueRetrySchedulerTests`
  - `BookQuotesTests/CaptureQueueSupportTests`
  - `BookQuotesTests/CaptureQueueStoreTests`
- Simulator build passed.
- Onboarding UI smoke attempted:
  - `BookQuotesUITests/OnboardingFlowTests/testOnboarding_WelcomeCarousel_DisplaysAllPages`
  - Result: failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Follow-Up

- Issue 040 introduced a controllable polling/observer adapter and removed the one-second polling loop from `CaptureQueueManager`.
- Remaining queue risk is now concentrated around processing task lifecycle, extraction dependency behavior, cancellation, retry scheduling, and stats publication.
