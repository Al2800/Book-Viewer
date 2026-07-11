# Capture Save Routing Regressions

Date: 2026-07-11

Issues:

- `083-quote-save-navigation-after-extraction-review.md`
- `084-cover-capture-created-book-visibility.md`

## Characterization

The recovered AX runner smoke made the failures deterministic at app assertion level:

- `QuoteCaptureFlowTests.testSaveQuotes_NavigatesToLibrary` reached `ExtractionReviewView`, tapped `Save All`, then did not observe the expected post-save route.
- `CoverCaptureFlowTests.testCoverCapture_TestCoverButton_CanSaveBook` created a book from mocked cover capture, then did not observe the created title.

Red bundles:

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-54-23-+0100.xcresult
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_22-55-21-+0100.xcresult
```

## Production Change

The app shell now owns the cross-tab completion route:

```text
Capture completion -> ContentView.openBookInLibrary -> LibraryTab pending book navigation -> BookDetailView
```

This keeps `CaptureTabRootView` focused on capture flow state while `ContentView` coordinates tab selection and `LibraryTab` owns Library navigation.

Quote save now uses a one-tap `Save All` action. The existing duplicate checks and persistence path remain in place; the extra confirmation dialog was removed because it prevented the expected save-and-route behavior.

## Verification

Focused UI regression:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes \
  -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testSaveQuotes_NavigatesToLibrary \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result: passed.

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_23-01-21-+0100.xcresult
```

Adjacent unit gate:

```sh
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes \
  -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/CaptureFlowStateTests \
  -only-testing:BookQuotesTests/QuoteSaveDraftTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests
```

Result: passed.

```text
/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.11_23-03-20-+0100.xcresult
```
