# Issue 040: Capture Queue Network Observer Refactor

Status: closed

## Problem

`CaptureQueueManager` still owned the restored-connection polling loop directly. That made the user-visible offline queue behavior harder to characterize because tests either had to tolerate real one-second sleeps or avoid the network restoration path entirely.

The manager should keep the public queue lifecycle, but the polling loop should sit behind a small seam so restored-connection behavior can be exercised deterministically.

## Acceptance Criteria

- Characterize restored-connection observation before production edits.
- Preserve starting network monitoring when observation begins.
- Preserve processing start when a poll observes offline-to-online and auto-processing is enabled.
- Avoid real sleeps in the characterization test.
- Keep `CaptureQueueManager.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby capture queue characterization tests.
- Run simulator build.
- Attempt onboarding simulator UI smoke and record runner result.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Services/CaptureQueueNetworkObserver.swift`.
- Added `BookQuotesTests/Unit/Services/CaptureQueueNetworkObserverTests.swift`.
- Updated `CaptureQueueManager` to delegate restored-connection polling to `CaptureQueueNetworkObserver`.
- Added `CaptureQueueNetworkPoller` as the live one-second polling adapter and kept tests on a scripted poller.

## LOC Result

- `BookQuotes/Services/CaptureQueueManager.swift`: 301 LOC -> 289 LOC.
- `BookQuotes/Services/CaptureQueueNetworkObserver.swift`: 56 LOC.
- `BookQuotes/Services/CaptureQueueNetworkTransition.swift`: remains 11 LOC.
- `BookQuotes/Services/CaptureQueueNetworkMonitoring.swift`: remains 10 LOC.

The manager remains below the 500 LOC target and now exposes less timing detail to future queue changes.

## Verification

- Focused red test confirmed missing observer/poller production module before implementation:
  - `BookQuotesTests/CaptureQueueNetworkObserverTests`
- Focused green test passed:
  - `BookQuotesTests/CaptureQueueNetworkObserverTests`
- Nearby queue characterization passed:
  - `BookQuotesTests/CaptureQueueNetworkObserverTests`
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

## Residual Risk / Next Slice

- Queue processing orchestration still lives in `CaptureQueueManager`; that is acceptable for now because the manager is under 500 LOC and the storage, retry, preferences, connectivity, transition, and observation seams are characterized.
- Future queue work should target processing lifecycle only when changing extraction dependency behavior, cancellation behavior, retry scheduling, or stats publication.
