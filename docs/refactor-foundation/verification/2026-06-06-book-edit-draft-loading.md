# Book Edit Draft Loading Verification - 2026-06-06

## Slice

Extracted the book-edit draft/loading seam from `BookEditView.swift`.

## Files

- `BookQuotes/Features/BookRegistration/BookEditDraft.swift`: source-to-form draft mapping.
- `BookQuotes/Features/BookRegistration/BookEditOptions.swift`: genre options and labels.
- `BookQuotes/Features/BookRegistration/BookEditView.swift`: now applies `BookEditDraft` instead of mapping every field inline.
- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`: UI-test-only cover button now injects deterministic metadata.
- `BookQuotesTests/Unit/BookRegistration/BookEditDraftTests.swift`: characterization tests.
- `BookQuotesUITests/Flows/CoverCaptureFlowTests.swift`: keeps cover acceptance aligned with deterministic test affordance.

## LOC Check

```text
659 BookQuotes/Features/BookRegistration/BookEditView.swift
 88 BookQuotes/Features/BookRegistration/BookEditDraft.swift
 57 BookQuotes/Features/BookRegistration/BookEditOptions.swift
956 BookQuotes/Features/BookRegistration/CoverCaptureView.swift
 72 BookQuotesTests/Unit/BookRegistration/BookEditDraftTests.swift
380 BookQuotesUITests/Flows/CoverCaptureFlowTests.swift
```

`BookEditView.swift` remains above the sub-500 LOC target. Remaining extraction targets: save orchestration, cover/image picker adapter, and smaller UI sections.

## Test Results

Red test:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditDraftTests
```

Result: failed as expected because `BookEditDraft` and `BookEditOptions` did not exist.

Green focused unit:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditDraftTests
```

Result: passed, 2 tests.

Model guard:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BookEditDraftTests -only-testing:BookQuotesTests/BookModelTests
```

Result: passed, 23 tests.

Simulator acceptance:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateBook_WithRequiredFields \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testManualEntry_CreateThenEditBook_UpdatesTitle \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit
```

Result: passed, 3 UI tests.

## Warnings

The test runs still emit existing Swift 6/concurrency and availability warnings outside this slice, including `SearchDatabase`, `QuoteSaveService`, `BatchProcessingService`, `CaptureQueueManager`, `CameraService`, and some symbol-effect availability warnings.
