# TestFlight Build 22 Capture Regression Diagnosis

Date: 2026-06-06

## Scope

Diagnosed TestFlight build 22 reports:

- Quote capture returns no quotes after sign-in on pages that previously worked.
- Cover/title capture includes praise, bestseller, or other cover copy as title metadata.
- Cover photo capture can freeze on a white screen after accepting the cropped cover.

## Changes

- Added characterization tests for quote extraction prompt behaviour when marked text is readable but boundaries are uncertain.
- Added characterization tests for cover metadata prompts rejecting praise, bestseller, and marketing copy.
- Added OCR fallback characterization for noisy front-cover lines before the true title.
- Updated quote extraction prompt to request best-effort marked text with lower confidence rather than empty quote arrays.
- Added `PageCapture.completeExtraction(with:)` so empty quote extraction results fail as `noQuotesFound` instead of completing a capture with zero quotes.
- Routed extraction review and batch processing completion through the same `PageCapture` extraction interface.
- Updated cover extraction prompt and OCR fallback filtering to reject common marketing lines.
- Updated cover metadata normalization so noisy Gemini title output is cleaned before book edit receives the metadata.
- Added OCR title fallback when Gemini returns only cover marketing text as the title.
- Updated cover crop accept flow to start processing after the full-screen crop review dismisses.
- Added cover crop lifecycle characterization so accepting a crop keeps full-screen content populated until the dismissal path consumes the pending cropped image.
- Added a focused simulator probe for crop accept dismissal before processing.

## Verification

- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests -only-testing:BookQuotesTests/CoverMetadataNormalizerTests -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests`
  - Passed: 14 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests -only-testing:BookQuotesTests/CoverMetadataNormalizerTests -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests -only-testing:BookQuotesTests/CoverOCRHeuristicsTests`
  - Passed: 22 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/PageCaptureTests`
  - Passed: 5 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests`
  - Passed: 5 tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText`
  - Passed: 2 UI tests.
- `xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit`
  - Passed: 1 UI test.
- `xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverCropGeometryTests`
  - Passed.
- `xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing`
  - Completed without failure.
- `xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit`
  - Completed without failure.

## Remaining Risk

- The quote symptom may still include a backend/proxy or model-response regression, but the app no longer treats a valid `quotes: []` response as a successful extraction with no quotes.
- Real device camera capture still needs manual TestFlight confirmation because simulator camera mocking is not identical to the physical camera and crop interaction.
- No real failing noisy cover image is checked into the repo, so noisy-cover validation still needs a manual simulator or TestFlight check before release.
- Issue 006 is closed and the fixture-based simulator route into extraction review is now passing.
