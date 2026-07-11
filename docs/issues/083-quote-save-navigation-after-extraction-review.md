# Issue 083: Quote Save Navigation After Extraction Review

Status: `closed`

## Context

The recovered issue 081 XCUITest smoke reached app assertions on 2026-07-11. `QuoteCaptureFlowTests.testSaveQuotes_NavigatesToLibrary` failed after tapping `Save All` in `ExtractionReviewView`.

The extraction review itself was healthy in the same smoke:

- `QuoteCaptureFlowTests.testExtractionReview_DisplaysExtractedQuotes` passed.
- The save button was found as `Save All`.
- After tapping save, the test did not observe either the expected `Quotes` screen signal or a tab bar within the current timeout.

Result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-45-29-+0100.xcresult
```

Failure:

```text
QuoteCaptureFlowTests.swift:257: XCTAssertTrue failed - Should navigate after save
```

## Characterization Plan

- Re-run the single failing test to confirm whether the failure is deterministic.
- Inspect the failure screenshot/view hierarchy to identify the post-save screen.
- Characterize whether `ExtractionReviewView.persistApprovedQuotes()` calls `onComplete` and `dismiss()` after a full-success save in the mocked-camera path.
- Confirm whether the UI contract should be return-to-book-detail, return-to-library, or remain in review with a success state.

## Acceptance Criteria

- [x] The post-save route is explicit and documented for quote capture.
- [x] A focused UI test verifies the chosen route.
- [x] The test was not weakened; production behavior was changed to satisfy the existing behavior expectation.
- [x] Focused adjacent unit coverage was run for capture/save state seams.
- [x] Verification recorded in `docs/refactor-foundation/verification/`.

## Resolution

Resolved on 2026-07-11.

`Save All` now starts the existing quote persistence flow directly instead of opening an additional confirmation dialog. After a successful save, the capture tab reports the selected book to the app shell, which switches to Library and opens that book detail.

The route is now:

```text
ExtractionReviewView Save All -> persist quotes -> QuoteCaptureView completion -> CaptureTabRootView completion -> ContentView.openBookInLibrary -> LibraryTab opens BookDetailView
```

The original failure was reproduced before the fix:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-54-23-+0100.xcresult
```

Green verification:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_23-01-21-+0100.xcresult
```

Command:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes \
  -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testSaveQuotes_NavigatesToLibrary \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

## Refactor Impact

Likely areas:

- `BookQuotes/Features/QuoteCapture/ExtractionReviewView.swift`
- `BookQuotes/Features/QuoteCapture/ExtractionReviewProcessor.swift`
- `BookQuotes/App/CaptureTabRootView.swift` or the surrounding capture completion route, if `onComplete` is not wired as expected.

This should be handled before deeper Library/QuoteDetail refactors if it affects the core capture-save workflow.
