# Onboarding Step and Capture Queue Processing Characterization

Date: 2026-06-30

Issue: `docs/issues/018-onboarding-step-and-capture-queue-processing-refactor.md`

## Baseline Behaviour

This slice preserves the existing first-run onboarding flow and offline capture queue behaviour while moving presentation and processing work behind more focused modules.

Onboarding behaviours:

- Welcome carousel starts on "Capture Quotes Instantly".
- Continue advances welcome pages.
- Skip and Get Started route to "Create Your Account".
- Simulator/auth skip can continue from sign-in via "Maybe later".
- Legal links still present the legal document sheet.
- Subscription-enabled builds still route through "Choose Your Plan".
- Paywall "Maybe later" continues to marking setup.
- Marking setup shows "How Do You Mark Books?" with marking options.
- "Continue" and "Use defaults" route to completion.
- "Start Capturing" stores onboarding completion flags, fires success haptic, calls the completion callback, and dismisses.

Capture queue behaviours:

- Initial queue stats are zero.
- Queue stats total active items and status descriptions still derive from persisted item status.
- Queue item state transitions for processing, failed, retry, cancelled, and completed are unchanged.
- Pending and failed descriptors still filter by status.
- Queue errors still expose user-readable descriptions.
- Stats publisher still emits on queue changes.
- Start/stop lifecycle remains crash-free.
- Add/remove/retry/cancel/cleanup remain owned by the actor.
- Processing still loads the queued image, fetches enabled marking definitions, calls the extraction service, creates `Quote` rows, marks completion, marks failures, and schedules retries when allowed.

## Characterization Used

Queue baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result before edits:

- Passed.
- Runtime: `30.783` seconds.

Onboarding baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests
```

Result before edits:

- Failed before app assertions.
- XCTest UI runner error: `Timed out waiting for AX loaded notification`.
- Runtime before failure: `100.317` seconds.

Initial parallel test attempt:

- Running queue and onboarding `xcodebuild test` jobs concurrently against the same DerivedData path caused a build database lock.
- This was a runner setup issue, not an app failure.

## Extracted Modules

- `OnboardingStepViews.swift`: welcome carousel, sign-in step, subscription step, marking setup step, and completion step presentation.
- `CaptureQueueProcessing.swift`: queued item extraction transaction, including image loading, enabled marking prompt fetch, model extraction call, quote insertion, completion mutation, failure mutation, and processing outcome reporting.

## Non-Goals

- No change to onboarding copy, button labels, legal link behaviour, step order, subscription skip path, marking setup defaults, or completion persistence.
- No change to queue retry delays, max concurrency setting, network observation, stats shape, queue item descriptors, image storage, thumbnail generation, or extraction service selection.
- No test edits to make the refactor pass.
