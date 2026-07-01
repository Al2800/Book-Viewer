# Onboarding Completion and Capture Queue Store Characterization

Date: 2026-06-30

Issue: `docs/issues/029-onboarding-completion-and-capture-queue-store-refactor.md`

## Baseline Behaviour

Onboarding:

- Completing onboarding persists `hasCompletedOnboarding`.
- Completing onboarding enables `showFirstCaptureCoaching`.
- `OnboardingView` still fires success haptic, calls `onComplete`, and dismisses.

Capture queue:

- Enqueue stores the image file and thumbnail.
- Enqueue preserves item priority and pending status.
- Queue stats still count pending, processing, failed, and completed items.
- The next pending item lookup still follows the existing queue descriptor.
- Retry resets a failed item to pending and clears its error while preserving retry count.
- Cancel marks an item cancelled.
- Remove deletes the queue row and associated image file.
- `CaptureQueueManager` still owns pending retry task cancellation around remove/cancel.

## Characterization Used

Baseline before edits:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnboardingFlowPolicyTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/CaptureQueueSupportTests \
  -only-testing:BookQuotesTests/CaptureQueueItemTests
```

Result:

- Passed.
- Runtime: `29.273` seconds.

New characterization:

- `OnboardingCompletionStoreTests`
- `CaptureQueueStoreTests`

## Non-Goals

- No change to onboarding copy, step order, legal sheets, subscription routing, haptics, callbacks, or dismissal.
- No change to queue retry delays, network polling, extraction processing, retry task timing, stats publisher shape, or shared manager initialization.
