# Onboarding Policy and Capture Queue Support Characterization

Date: 2026-06-30

Issue: `docs/issues/024-onboarding-policy-and-capture-queue-support-refactor.md`

## Baseline Behaviour

This slice preserves existing onboarding route decisions and capture queue lifecycle behavior while moving deterministic decisions into focused modules.

Onboarding behaviours:

- Normal onboarding starts at the welcome carousel.
- TestFlight/App Store media subscription capture can start directly at the subscription screen.
- Sign-in continuation routes to subscription when subscriptions are enabled.
- Sign-in continuation skips subscription and routes to marking setup when subscriptions are disabled.
- Onboarding UI labels, sheets, completion persistence, haptics, and dismissal are unchanged.

Capture queue behaviours:

- Initial queue stats remain zero.
- Queue item state transitions remain unchanged.
- Pending and failed descriptors still filter by status.
- Queue errors still expose user-readable descriptions.
- Stats publisher still emits on queue changes.
- Start/stop lifecycle remains crash-free.
- Add/remove/retry/cancel/cleanup remain owned by the actor.
- Retry delays remain `5`, `30`, and `120` seconds and clamp out-of-range retry counts to the nearest configured delay.

## Characterization Used

Queue baseline before edits:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result before edits:

- Passed.
- Runtime: `37.971` seconds.

Onboarding baseline before edits:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests
```

Result before edits:

- Failed before app assertions.
- XCTest UI runner error: `Early unexpected exit, operation never finished bootstrapping`.
- Runtime before failure: `61.730` seconds.

## New Characterization Added

- `OnboardingFlowPolicyTests`: covers initial step and post-sign-in route decisions.
- `CaptureQueueSupportTests`: covers retry delay clamping and queue status aggregation.

## Non-Goals

- No change to onboarding copy, button labels, legal link behavior, step order, completion side effects, or embedded paywall presentation.
- No change to queue image storage, thumbnail generation, SwiftData persistence, network observation, extraction service selection, retry delays, or processing transaction behavior.
