# Onboarding and Capture Queue Refactor Characterization

Date: 2026-06-14

Issue: `docs/issues/016-onboarding-and-capture-queue-modular-refactor.md`

## Baseline Behaviour

This slice keeps onboarding and offline queue behaviour intact while extracting presentation and support types.

Onboarding behaviours:

- Welcome carousel displays capture, organize, and discover pages.
- Continue advances carousel pages.
- Get Started and Skip navigate to sign-in.
- Sign-in step shows account copy and legal links.
- Marking setup shows available marking options.
- Use defaults advances to completion.
- Completion shows success state and Start Capturing dismisses onboarding.
- Page swipes still move through the carousel.

Capture queue behaviours:

- Initial stats are zero.
- Queue stats derive active item counts and status descriptions.
- Queue items transition through pending, processing, failed, retry, cancelled, and completed states.
- Queue descriptors fetch pending/failed items correctly.
- Queue errors expose user-readable descriptions.
- Stats publisher emits on queue changes.
- Queue add/remove/start/stop flows persist through SwiftData.
- Queue item image paths and thumbnails are persisted.
- Queue priority values are preserved.
- Adding an item for a non-existent book throws.

## Characterization Used

Queue baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/OfflineQueueFlowTests
```

Result before edits:

- Passed.
- Runtime: `10.587` seconds.

Onboarding baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/OnboardingFlowTests
```

Result before edits:

- Passed.
- Runtime: `124.777` seconds.

## Extracted Modules

- `OnboardingWelcomeViews.swift`: welcome page data and carousel page presentation.
- `OnboardingMarkingViews.swift`: marking template selector and marking option buttons.
- `OnboardingPaywallViews.swift`: embedded onboarding paywall, media subscription plans, and media plan option card.
- `CaptureQueueTypes.swift`: queue stats and queue errors.
- `CaptureQueueShared.swift`: shared queue manager initialization.

## Non-Goals

- No change to onboarding copy, order, step transitions, legal links, subscription skip path, or completion side effects.
- No change to queue processing, retry delays, network observation, image storage, thumbnail generation, SwiftData fetches, or Gemini extraction calls.
- No test edits to make the refactor pass.
