# Quote Capture Session Store Verification

Date: 2026-06-30

Issue: `docs/issues/025-quote-capture-session-store-refactor.md`

## Changes

- Added `QuoteCaptureSessionStore` as the seam for confirmed-image persistence.
- Added `QuoteCaptureSessionStoreTests` for normal persistence and UI-test seeding.
- `QuoteCaptureView` now keeps camera/UI orchestration and delegates the SwiftData/image-file transaction.

## LOC Delta

- `BookQuotes/Features/Capture/QuoteCaptureView.swift`: 469 LOC -> 412 LOC.
- `BookQuotes/Features/Capture/QuoteCaptureSessionStore.swift`: 86 LOC.
- `BookQuotesTests/Unit/Capture/QuoteCaptureSessionStoreTests.swift`: 67 LOC.

## Verification

Red step:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/QuoteCaptureSessionStoreTests
```

Result before production code:

- Failed to compile because `QuoteCaptureSessionStore` did not exist.

Focused new unit tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/QuoteCaptureSessionStoreTests
```

Result after production code:

- Passed.
- Runtime: `57.511` seconds.

Session/page/store characterization:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureSessionTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/QuoteCaptureSessionStoreTests
```

Result:

- Passed when rerun alone.
- Runtime: `31.282` seconds.

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Quote-capture UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testImageReview_ShowsQualityIndicator
```

Result:

- Failed before app assertions.
- XCTest UI runner error: `Timed out waiting for AX loaded notification`.

## Residual Risk

- User-visible quote-capture flow still needs confirmation in a healthy simulator/TestFlight run because the UI runner is currently failing before it can assert app state.
- The unit tests cover the extracted persistence behavior directly and use the real image preprocessing/file storage path.
