# Quote Capture Session Store Characterization

Date: 2026-06-30

Issue: `docs/issues/025-quote-capture-session-store-refactor.md`

## Baseline Behaviour

This slice preserves the single-page quote capture behavior after the user confirms a captured image.

Normal confirmed-photo behavior:

- A new `CaptureSession` is created for the selected book.
- A single `PageCapture` is created with `orderIndex == 0`.
- The processed full image is written under the session capture directory.
- Thumbnail data is created and stored on the page capture.
- The page remains pending.
- The session is marked `readyToProcess`.
- The session is saved before opening extraction review.

UI-test confirmed-photo behavior:

- The same session/page relationship is created.
- The seeded quote remains `Test quote extracted for UI testing.`.
- The seeded page number remains `12`.
- The page is completed.
- The session records one success and becomes completed.

## Characterization Used

Model/session baseline before edits:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureSessionTests \
  -only-testing:BookQuotesTests/PageCaptureTests
```

Result before edits:

- Passed when run alone.
- Runtime: `27.979` seconds.

Initial concurrent UI smoke attempt before edits:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testImageReview_ShowsQualityIndicator
```

Result:

- Failed during the concurrent baseline run.
- The reliable post-change solo run is recorded in verification and failed before app assertions with an AX runner timeout.

## New Characterization Added

- `QuoteCaptureSessionStoreTests.testCreateSessionPersistsSinglePendingPageForCapturedImage`
- `QuoteCaptureSessionStoreTests.testCreateSessionCanSeedExtractionForUITestReviewFlow`

## Non-Goals

- No change to camera authorization, session setup, capture button behavior, preview crop behavior, document auto-crop, image quality analysis, image review presentation, extraction review presentation, completion/cancel callbacks, haptics, or error text.
- No change to extraction model selection or quote extraction behavior.
