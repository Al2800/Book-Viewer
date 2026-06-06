# Batch Capture Lifecycle Refactor Verification

Date: 2026-06-06

Issue: `docs/issues/003-batch-capture-view-lifecycle-refactor.md`

## LOC Delta

Before:

- `BatchCaptureView.swift`: 754 LOC

After:

- `BatchCaptureView.swift`: 400 LOC
- `BatchCaptureLifecycleState.swift`: 51 LOC
- `BatchCaptureSupplementaryViews.swift`: 339 LOC
- `BatchCaptureLifecycleStateTests.swift`: 45 LOC

All production files touched in this slice are below the 500 LOC target.

## Tests

Red characterization check:

- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BatchCaptureLifecycleStateTests`
- Result before production module: failed because `BatchCaptureLifecycleState` and `BatchCaptureLifecycleCommand` did not exist.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.06.06_17-36-04-+0100.xcresult`

Green focused unit check:

- Same command after adding the lifecycle module.
- Result: passed, 3 tests, 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.06.06_17-38-12-+0100.xcresult`

Selected simulator acceptance:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/BatchCaptureLifecycleStateTests \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_OpensFromCaptureTab \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_CapturePhoto_IncrementsCounter \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_AfterCapture_ShowsThumbnail \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_DoneButton_EnabledAfterCapture \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_SaveDraftOption_SavesWithoutProcessing \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_CancelWithCaptures_ShowsConfirmation
```

Result:

- `TEST SUCCEEDED`
- Unit: 3 tests passed.
- UI: 6 tests passed.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.06.06_17-40-27-+0100.xcresult`

Additional simulator acceptance for moved detail sheet:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_ThumbnailDetail_CanRemoveCapture
```

Result:

- `TEST SUCCEEDED`
- UI: 1 test passed.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.06.06_17-44-58-+0100.xcresult`

Post-warning-cleanup focused check:

- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/BatchCaptureLifecycleStateTests`
- Result: passed, 3 tests, 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.06.06_17-43-38-+0100.xcresult`

## Behaviour Notes

No intentional user-visible behaviour changes.

The parent view now keeps camera setup, capture execution, image preprocessing handoff, model persistence, queue orchestration, haptics, milestones, and callbacks. Lifecycle decisions moved to `BatchCaptureLifecycleState`; thumbnail/detail/offline confirmation UI moved to `BatchCaptureSupplementaryViews`.

Offline queue side effects were not simulator-tested in this slice. The deterministic offline completion decision is covered by unit tests, and the existing async queue insertion path was left in place.
