# Issue 081: XCUITest AX Runner Initialization

Status: `closed`

## Context

After the broad unit gate passed, the next required checkpoint was a deeper simulator smoke through seeded library, mock quote capture, extraction review, save, and cover-capture save flows.

The focused XCUITest command did not reach app assertions. The test runner failed during UI automation startup:

```text
Failed to initialize for UI testing: Error Domain=XCTDaemonErrorDomain Code=18 "Timed out waiting for AX loaded notification"
```

The same AX initialization error reproduced after:

- shutting down the booted iPhone 17 simulator.
- killing stale `BookQuotesUITests-Runner` processes.
- rebooting the same simulator and waiting for boot completion.
- retrying a single seeded-library UI test.

The single seeded-library UI test was also retried on a fresh available iPhone 17 simulator device. That run also failed before app assertions with:

```text
Failed call to AXDisableAccessibilityOnTermination: kAXErrorCannotComplete
```

The retry was then repeated with only the iOS 26.5 iPhone 17 simulator booted and addressed by explicit simulator id. That also failed before app assertions with:

```text
Timed out waiting for AX loaded notification
```

Manual `simctl launch` with the same seeded/mock-camera arguments succeeded and showed seeded Library data.

## Acceptance Criteria

- Reproduce or clear the AX runner initialization failure on a clean simulator session.
- Run the focused UI smoke set:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testSaveQuotes_NavigatesToLibrary \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

- If AX remains unstable on the current simulator, retry on a fresh available simulator device.
- Record the result bundle path for any remaining infrastructure failure.
- Do not treat this as a product failure unless a test method reaches app assertions and fails.

## Implementation

No production code changes. This was an environment/infrastructure verification issue.

After MacinCloud restored the `user298279` uid/session record, the same focused UI smoke reached app assertions on the booted iOS 26.5 iPhone 17 simulator. That clears the AX bootstrap failure as the active blocker.

## Verification

Recovered focused UI smoke:

```text
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testSaveQuotes_NavigatesToLibrary \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result: runner initialized and reached app assertions.

Result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-45-29-+0100.xcresult
```

Passed:

- `LibraryManagementTests.testLibrary_ShowsSeededBooks`
- `QuoteCaptureFlowTests.testExtractionReview_DisplaysExtractedQuotes`

Failed at app assertions, tracked separately:

- `083-quote-save-navigation-after-extraction-review.md`
- `084-cover-capture-created-book-visibility.md`

Failed focused UI smoke result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-33-00-+0100.xcresult
```

Failed single seeded-library retry result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-35-02-+0100.xcresult
```

Failed fresh iPhone 17 seeded-library retry result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-38-36-+0100.xcresult
```

Failed explicit single-booted iOS 26.5 retry result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_07-41-27-+0100.xcresult
```

Manual seeded/mock-camera launch:

```bash
xcrun simctl launch booted com.acampbell.bookquotes --uitesting --preload-library-test-data --mock-camera -AppleLanguages '(en)' -AppleLocale en_US
xcrun simctl io booted screenshot docs/refactor-foundation/verification/screenshots/2026-07-01-seeded-mock-camera-launch.png
```

Result: app launched and screenshot showed seeded Library data with 3 books and 6 quotes.

## Follow-Up

- Use issues `083` and `084` for the product/test-contract failures surfaced by the recovered runner.
- Keep using the focused UI smoke as the pre-submission simulator confidence gate.
