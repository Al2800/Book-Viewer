# Issue 038: Onboarding and Capture Queue Network Monitoring Refactor

Status: closed

## Problem

`OnboardingView` is now mainly a flow coordinator, but its explicit step advancement needed a fresh characterization point before further onboarding changes. `CaptureQueueManager` still depended directly on the concrete `NetworkMonitor`, making offline/online queue behavior hard to test without real network state.

## Acceptance Criteria

- Characterize explicit onboarding step advancement before production edits in the onboarding area.
- Preserve signed-in user state when onboarding advances to an explicit step.
- Introduce a small queue connectivity seam so tests can inject network state.
- Keep `NetworkMonitor` as the live app adapter.
- Preserve queue start behavior: monitoring starts and offline state remains idle.
- Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- Run focused onboarding and capture queue tests.
- Run full `CaptureQueueManagerTests`.
- Run simulator build.
- Attempt onboarding simulator UI smoke and record runner result.
- Update architecture and refactor-foundation docs.

## Result

- Added onboarding characterization coverage to `OnboardingSessionStateTests`.
- Added `BookQuotes/Services/CaptureQueueNetworkMonitoring.swift`.
- Updated `NetworkMonitor` to conform to the queue connectivity seam.
- Updated `CaptureQueueManager` and shared initialization to accept `any CaptureQueueNetworkMonitoring`.
- Added a controlled network-monitor characterization test for queue manager startup.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: remains 160 LOC.
- `BookQuotes/Features/Onboarding/OnboardingSessionState.swift`: remains 30 LOC.
- `BookQuotes/Services/CaptureQueueManager.swift`: remains 298 LOC.
- `BookQuotes/Services/CaptureQueueNetworkMonitoring.swift`: 10 LOC.

## Verification

- Focused onboarding/queue characterization passed:
  - `BookQuotesTests/OnboardingSessionStateTests`
  - `BookQuotesTests/OnboardingFlowPolicyTests`
  - `BookQuotesTests/OnboardingCompletionStoreTests`
  - `BookQuotesTests/OnboardingAuthSkipPolicyTests`
  - `BookQuotesTests/CaptureQueueManagerTests/testStartUsesInjectedNetworkMonitorAndRemainsIdleWhenOffline`
  - `BookQuotesTests/CaptureQueueProcessingPreferencesTests`
  - `BookQuotesTests/CaptureQueueRetrySchedulerTests`
  - `BookQuotesTests/CaptureQueueSupportTests`
  - `BookQuotesTests/CaptureQueueStoreTests`
- Full `BookQuotesTests/CaptureQueueManagerTests` passed.
- Simulator build passed.
- Onboarding UI smoke attempted:
  - `BookQuotesUITests/OnboardingFlowTests/testOnboarding_WelcomeCarousel_DisplaysAllPages`
  - Result: failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- The new connectivity seam lets future queue slices characterize online restoration without real network state.
- Issue 039 characterized the restored-connection transition rule. `CaptureQueueManager` still owns the polling loop and processing task lifecycle.
