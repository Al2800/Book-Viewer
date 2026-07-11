# Issue 084: Cover Capture Created Book Visibility

Status: `closed`

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

- [x] The cover-capture save completion route is explicit and documented.
- [x] A focused UI test verifies the chosen route.
- [x] The saved book appears after dismissal by routing to Library and opening the created book.
- [x] The test was not loosened.
- [x] Verification recorded in `docs/refactor-foundation/verification/`.

## Resolution

Resolved on 2026-07-11.

Cover capture completion now passes the created book to the app shell. The app switches to Library and `LibraryTab` consumes the pending book navigation request by opening `BookDetailView` for that book.

The route is now:

```text
CoverCaptureFlowView completion -> CaptureTabRootView completion -> ContentView.openBookInLibrary -> LibraryTab opens BookDetailView
```

The original failure was reproduced before the fix:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-55-21-+0100.xcresult
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

- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`
- `BookQuotes/Features/BookRegistration/BookEditView.swift`
- `BookQuotes/App/CaptureTabRootView.swift` or Library add-book presentation routing, if completion is not propagated to the tab/root shell.

This belongs with the capture/book-registration refactor surface rather than the Library LOC slice.
