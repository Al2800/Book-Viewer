# Capture Flow State Verification - 2026-06-06

## Slice

Extracted deterministic capture-tab flow transitions from `CaptureTabRootView.swift` into `CaptureFlowState.swift`.

## Files

- `BookQuotes/Features/Capture/CaptureFlowState.swift`: pure state reducer for capture mode, quote/batch flow identity refreshes, and selected-book clearing commands.
- `BookQuotes/Features/Capture/CaptureTabRootView.swift`: delegates transition decisions to `CaptureFlowState` while retaining SwiftUI rendering, haptics, selected `Book`, permission/coaching, and `onBookCreated`.
- `BookQuotesTests/Unit/Capture/CaptureFlowStateTests.swift`: characterization tests for mode selection, book selection, completion, cancellation, and add-new-book transitions.
- `docs/refactor-foundation/characterization/capture-flow-state.md`: current transition map and seam boundary.

## LOC Check

```text
812 BookQuotes/Features/Capture/CaptureTabRootView.swift
 92 BookQuotes/Features/Capture/CaptureFlowState.swift
 95 BookQuotesTests/Unit/Capture/CaptureFlowStateTests.swift
 51 docs/refactor-foundation/characterization/capture-flow-state.md
```

`CaptureTabRootView.swift` moved from 840 LOC to 812 LOC. It remains above the sub-500 LOC target, so the next capture slices should extract orchestration and presentation sections rather than adding more inline flow logic.

## Test Results

Red test:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CaptureFlowStateTests
```

Result: failed as expected before `CaptureFlowState.swift` existed.

Focused unit rerun:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CaptureFlowStateTests \
  -only-testing:BookQuotesTests/BookEditDraftTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests \
  -only-testing:BookQuotesTests/CoverMetadataNormalizerTests \
  -only-testing:BookQuotesTests/BookModelTests
```

Result: passed, 33 tests.

Simulator acceptance:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testCaptureTab_CaptureButton_Exists \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_OpensFromCaptureTab
```

Result: passed, 3 UI tests.

## Warnings

The test runs still emit existing warnings outside this slice:

- Swift 6 actor/sendability warnings in `SearchDatabase`, `QuoteSaveService`, `BatchProcessingService`, `CaptureQueueManager`, and test infrastructure.
- Availability warnings around `symbolEffect`.
- `BookQuotesApp` and `ExtractionReviewView` unreachable `catch` warnings.
- Simulator UI-test noise about LLDB debugger version and duplicated Web accessibility classes.
