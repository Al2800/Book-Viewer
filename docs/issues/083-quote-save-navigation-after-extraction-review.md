# Issue 083: Quote Save Navigation After Extraction Review

Status: `open`

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

- The post-save route is explicit and documented for quote capture.
- A focused UI test verifies the chosen route using stable accessibility identifiers rather than only generic text like `Quotes`.
- The test must only be changed after the intended product behaviour is confirmed.
- Focused unit coverage should cover the save result path if a suitable non-UI seam exists.
- Record verification in `docs/refactor-foundation/verification/`.

## Refactor Impact

Likely areas:

- `BookQuotes/Features/QuoteCapture/ExtractionReviewView.swift`
- `BookQuotes/Features/QuoteCapture/ExtractionReviewProcessor.swift`
- `BookQuotes/App/CaptureTabRootView.swift` or the surrounding capture completion route, if `onComplete` is not wired as expected.

This should be handled before deeper Library/QuoteDetail refactors if it affects the core capture-save workflow.
