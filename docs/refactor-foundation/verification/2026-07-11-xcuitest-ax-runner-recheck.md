# XCUITest AX Runner Recheck - 2026-07-11

Issue: `docs/issues/081-xcuitest-ax-runner-initialization.md`

## Context

MacinCloud restored the `user298279` uid/session record after the earlier local macOS session failure. The previous XCUITest blocker was:

```text
Timed out waiting for AX loaded notification
```

## Health Check

- `whoami`: `user298279`
- `getconf DARWIN_USER_CACHE_DIR`: `/var/folders/r4/tzp6hmr97yvfych1fc2ggphm0000kp/C/`
- GitHub SSH authentication: passed.
- Simulator build: passed before this smoke.

## Focused UI Smoke

Command:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesUITests/LibraryManagementTests/testLibrary_ShowsSeededBooks \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testSaveQuotes_NavigatesToLibrary \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-45-29-+0100.xcresult
```

## Result

The AX runner initialized successfully and reached app assertions. Issue 081 is no longer the active blocker.

Passed:

- `LibraryManagementTests.testLibrary_ShowsSeededBooks`
- `QuoteCaptureFlowTests.testExtractionReview_DisplaysExtractedQuotes`

Failed at app assertions:

- `CoverCaptureFlowTests.testCoverCapture_TestCoverButton_CanSaveBook`
  - `CoverCaptureFlowTests.swift:258`
  - `XCTAssertTrue failed - Created book title should appear`
  - Tracked by `docs/issues/084-cover-capture-created-book-visibility.md`.
- `QuoteCaptureFlowTests.testSaveQuotes_NavigatesToLibrary`
  - `QuoteCaptureFlowTests.swift:257`
  - `XCTAssertTrue failed - Should navigate after save`
  - Tracked by `docs/issues/083-quote-save-navigation-after-extraction-review.md`.

## Decision

Close issue 081 as infrastructure-resolved. Do not treat the two failing tests as AX/simulator failures; they are now product or test-contract issues requiring characterization before code changes.
