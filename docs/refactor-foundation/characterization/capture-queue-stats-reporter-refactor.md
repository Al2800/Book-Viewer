# Capture Queue Stats Reporter Refactor Characterization

Date: 2026-07-01

## Scope

- `BookQuotes/Features/Onboarding/OnboardingView.swift`
- `BookQuotes/Services/CaptureQueueManager.swift`
- `BookQuotes/Services/CaptureQueueStatsReporter.swift`

## Existing Behaviour

- Onboarding remains a route shell around existing flow, session, auth skip, completion, step view, paywall, and marking-selection modules.
- Capture queue stats are exposed as:
  - a current `QueueStats` value;
  - a Combine publisher that emits updates for UI subscribers.
- Queue manager updates stats after lifecycle, processing, and queue mutation events.

## Characterization Added

- `CaptureQueueStatsReporterTests.testStartsWithEmptyQueueStats`
- `CaptureQueueStatsReporterTests.testPublishUpdatesCurrentStats`
- `CaptureQueueStatsReporterTests.testPublisherEmitsPublishedStats`

## Non-Goals

- No onboarding visual or flow changes.
- No queue processing trigger, retry, persistence, or extraction changes.
- No changes to the public `CaptureQueueManager` API.
