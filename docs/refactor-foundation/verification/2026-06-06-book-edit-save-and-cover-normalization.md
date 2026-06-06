# Book Edit Save and Cover Normalization Verification - 2026-06-06

## Slice

Extracted deterministic save mapping from `BookEditView.swift` and cover metadata normalization from `CoverCaptureView.swift`.

## Files

- `BookQuotes/Features/BookRegistration/BookEditSaveDraft.swift`: form-to-`Book` save mapping.
- `BookQuotes/Features/BookRegistration/CoverMetadataNormalizer.swift`: Gemini/OCR/manual cover metadata normalization.
- `BookQuotes/Features/BookRegistration/BookEditView.swift`: delegates create/update field assignment to `BookEditSaveDraft`.
- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`: delegates extraction mapping and author splitting to `CoverMetadataNormalizer`.
- `BookQuotes/App/ContentView.swift`, `BookQuotes/App/CaptureTab.swift`, `BookQuotes/Features/Capture/CaptureTabRootView.swift`: route cover-created completion back to the Library tab.
- `BookQuotesTests/Unit/BookRegistration/BookEditSaveDraftTests.swift`: save characterization tests.
- `BookQuotesTests/Unit/BookRegistration/CoverMetadataNormalizerTests.swift`: cover normalization characterization tests.
- `BookQuotesUITests/Flows/CoverCaptureFlowTests.swift`: asserts cover-created titles through row labels containing the generated title.

## LOC Check

```text
645 BookQuotes/Features/BookRegistration/BookEditView.swift
 77 BookQuotes/Features/BookRegistration/BookEditSaveDraft.swift
 88 BookQuotes/Features/BookRegistration/BookEditDraft.swift
 57 BookQuotes/Features/BookRegistration/BookEditOptions.swift
906 BookQuotes/Features/BookRegistration/CoverCaptureView.swift
 78 BookQuotes/Features/BookRegistration/CoverMetadataNormalizer.swift
308 BookQuotes/App/ContentView.swift
149 BookQuotes/App/CaptureTab.swift
840 BookQuotes/Features/Capture/CaptureTabRootView.swift
 72 BookQuotesTests/Unit/BookRegistration/BookEditDraftTests.swift
 85 BookQuotesTests/Unit/BookRegistration/BookEditSaveDraftTests.swift
104 BookQuotesTests/Unit/BookRegistration/CoverMetadataNormalizerTests.swift
381 BookQuotesUITests/Flows/CoverCaptureFlowTests.swift
```

`BookEditView.swift`, `CoverCaptureView.swift`, and `CaptureTabRootView.swift` remain above the sub-500 LOC target. Next extraction targets should be UI composition sections and capture flow state/orchestration.

## Test Results

Red tests:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditSaveDraftTests

xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverMetadataNormalizerTests
```

Result: failed as expected before `BookEditSaveDraft.swift` and `CoverMetadataNormalizer.swift` existed.

Focused units:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/BookEditDraftTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests \
  -only-testing:BookQuotesTests/CoverMetadataNormalizerTests \
  -only-testing:BookQuotesTests/BookModelTests
```

Result: passed, 29 tests.

Simulator acceptance:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateBook_WithRequiredFields \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateThenEditBook_UpdatesTitle \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Initial result: 3 passed, 1 failed. `testCoverCapture_TestCoverButton_CanSaveBook` exposed that the cover completion path needed to return to the Library tab, and the test needed to query the row label by title containment rather than exact static-text label.

Targeted rerun after fix:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result: passed, 1 UI test.

Final four-test simulator acceptance rerun:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateBook_WithRequiredFields \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateThenEditBook_UpdatesTitle \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook
```

Result: passed, 4 UI tests.

## Warnings

The test runs still emit existing warnings outside this slice:

- Swift 6 actor/sendability warnings in `SearchDatabase`, `QuoteSaveService`, `BatchProcessingService`, and `CaptureQueueManager`.
- Availability warnings around `symbolEffect`.
- `SignInView` switch exhaustiveness warnings.
- Simulator UI-test noise about LLDB debugger version and duplicated Web accessibility classes.
