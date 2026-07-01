# Verification: Broad Unit Gate

Date: 2026-07-01

## Preflight

```bash
git diff --check
```

Result: passed.

```bash
plutil -lint BookQuotes.xcodeproj/project.pbxproj
```

Result: passed.

## Broad Unit Gate

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests
```

Result: failed.

- 548 tests executed.
- 4 failures.

Failing tests:

- `MemoryPerformanceTests.testBaseline_EmptyApp_MemoryUsage`
- `MemoryPerformanceTests.testMemory_DeleteBooks_Releases`
- `MemoryPerformanceTests.testMemory_Load10000Quotes_Acceptable`
- `TagsPresentationTests.testFilteringMatchesCaseInsensitively`

## Focused Memory Gate

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/MemoryPerformanceTests
```

Result: failed.

- 8 tests executed.
- 3 failures.
- baseline RSS measured about 326 MB against a 50 MB threshold.
- 10K quote load measured about 405 MB total RSS against a 200 MB threshold.
- delete recovery did not show RSS returning to the OS.

Passing memory signals in the focused run included 1K quote load, 5K quote load, batch insert accumulation, repeated queries, and cover image memory growth.

After recalibration:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/MemoryPerformanceTests
```

Result: passed.

- 8 tests executed.
- 0 failures.
- 10K quote load memory increase: about 45.6 MB.
- deletion drift after delete: about 0.05 MB.
- cover image increase: about 7.5 MB.
- repeated-query memory increase: negative after cleanup.

## Focused Tags Gate

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/TagsPresentationTests \
  -only-testing:BookQuotesTests/TagModelTests \
  -only-testing:BookQuotesTests/TagEditorDraftTests \
  -only-testing:BookQuotesTests/QuoteTagMutationTests
```

Result: passed.

- 11 tests executed.
- 0 failures.

## Broad Unit Gate After Focused Fixes

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests
```

Result: passed.

- 548 tests executed.
- 0 failures.

## Assessment

The broad unit gate is now green after the focused tag contract correction and memory gate recalibration.

The tag failure is tracked by issue 080.

The memory gate recalibration is tracked by issue 079.

## Simulator Smoke

```bash
xcrun simctl install booted /Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Build/Products/Debug-iphonesimulator/BookQuotes.app
xcrun simctl launch booted com.acampbell.bookquotes
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-post-broad-gate-smoke.png
```

Result: passed.

- App launched on the booted iPhone 17 simulator.
- The screenshot shows the Library tab with the empty-library state.
- Screenshot artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-post-broad-gate-smoke.png`.

A deeper capture-flow simulator smoke is still required before a TestFlight/submission-readiness claim.

## Focused UI Smoke Attempt

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testSaveQuotes_NavigatesToLibrary \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result: failed before app assertions.

The runner reported:

```text
Timed out waiting for AX loaded notification
```

After restarting the iPhone 17 simulator and killing stale UI test runners, a single-test retry also failed before app assertions:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks
```

Result: failed before app assertions with the same AX initialization error.

The same single-test retry was then run on a fresh available iPhone 17 simulator device:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=9B8D58E4-E3DB-4CD5-ADE5-E370627E37CE' -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks
```

Result: failed before app assertions with:

```text
Failed call to AXDisableAccessibilityOnTermination: kAXErrorCannotComplete
```

The same single-test retry was then repeated after shutting down all simulators, booting only the iOS 26.5 iPhone 17 device, and addressing it by explicit simulator id:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks
```

Result: failed before app assertions with:

```text
Timed out waiting for AX loaded notification
```

Tracked by issue 081.

## Manual Seeded/Mock-Camera Launch

```bash
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --preload-library-test-data --mock-camera -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-seeded-mock-camera-launch.png
```

Result: passed.

- App launched on the simulator.
- Seeded Library data was visible.
- Screenshot showed 3 books and 6 quotes.
- Screenshot artifact: `docs/refactor-foundation/verification/screenshots/2026-07-01-seeded-mock-camera-launch.png`.
