# Cover Extraction Orchestration Verification

## Slice

Extracted deterministic cover metadata fallback decisions from `CoverCaptureView.swift` into `CoverExtractionOrchestrator.swift`.

## Files

- `BookQuotes/Features/BookRegistration/CoverExtractionOrchestrator.swift`: async seam for Gemini, OCR fallback, and manual fallback decisions.
- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`: delegates extraction orchestration while retaining concrete Gemini/OCR wiring, image data, UI state, and sheet presentation.
- `BookQuotesTests/Unit/BookRegistration/CoverExtractionOrchestratorTests.swift`: characterization tests for Gemini success, Gemini partial result, Gemini failure, OCR fallback, and manual fallback.
- `docs/refactor-foundation/characterization/cover-extraction-orchestration.md`: pre-extraction behavior map and acceptance notes.

## LOC

```text
893 BookQuotes/Features/BookRegistration/CoverCaptureView.swift
 33 BookQuotes/Features/BookRegistration/CoverExtractionOrchestrator.swift
115 BookQuotesTests/Unit/BookRegistration/CoverExtractionOrchestratorTests.swift
```

## Red

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests
```

Result: failed as expected before `CoverExtractionOrchestrator.swift` existed.

## Green

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests
```

Result: passed 4 tests.

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests \
  -only-testing:BookQuotesTests/CoverMetadataNormalizerTests \
  -only-testing:BookQuotesTests/BookEditDraftTests \
  -only-testing:BookQuotesTests/BookEditSaveDraftTests \
  -only-testing:BookQuotesTests/CaptureFlowStateTests
```

Result: passed 16 focused unit tests.

## Simulator Acceptance

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_PhotoMode_ShowsCaptureButton \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_CanSaveBook \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_ManualEntryLink_NavigatesToForm \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CancelButton_DismissesCaptureView
```

Result: passed 5 UI tests on iPhone 17 / iOS 26.5.

## Notes

- `CoverCaptureView.swift` is still too large at 893 LOC.
- The next cover slice should extract camera/crop presentation sections without changing the extraction seam.
- Existing Swift 6 warnings remain outside this slice.
