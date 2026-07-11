# Issue 084: Cover Capture Created Book Visibility

Status: `open`

## Context

The recovered issue 081 XCUITest smoke reached app assertions on 2026-07-11. `CoverCaptureFlowTests.testCoverCapture_TestCoverButton_CanSaveBook` failed after creating a book from the mocked cover capture flow.

The flow reached `BookEditView`, filled a generated title, tapped the stable save button, then failed to observe the generated title on the next screen.

Result bundle:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-45-29-+0100.xcresult
```

Failure:

```text
CoverCaptureFlowTests.swift:258: XCTAssertTrue failed - Created book title should appear
```

## Characterization Plan

- Re-run the single failing test to confirm whether the failure is deterministic.
- Inspect the failure screenshot/view hierarchy to identify where the app lands after save.
- Characterize whether `BookEditView.createBook()` calls `onSave` and dismisses immediately in the mocked cover path.
- Confirm whether `CoverCaptureView` should dismiss to Library, navigate to the new book detail, or keep the user in cover capture after creating the book.

## Acceptance Criteria

- The cover-capture save completion route is explicit and documented.
- A focused UI test verifies the chosen route with stable accessibility identifiers.
- If the saved book is expected to appear in Library, the test should assert both successful dismissal and persisted book visibility.
- The test must not be loosened to pass without confirming the intended product route.
- Record verification in `docs/refactor-foundation/verification/`.

## Refactor Impact

Likely areas:

- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`
- `BookQuotes/Features/BookRegistration/BookEditView.swift`
- `BookQuotes/App/CaptureTabRootView.swift` or Library add-book presentation routing, if completion is not propagated to the tab/root shell.

This belongs with the capture/book-registration refactor surface rather than the Library LOC slice.
