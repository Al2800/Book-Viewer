# Model-First Quote Extraction Verification

## Trigger

Build 28 TestFlight review showed better extraction quality than OCR-only, but still missed lines on a page where a side bracket marked a full paragraph and an underline appeared inside the marked span.

The product decision is that OCR is not sufficient as the first pass for quote capture. The remote vision model should be the primary extractor, with on-device OCR retained as fallback only.

## Changes

- `ModelAssistedQuoteExtractor` now calls the remote model extractor first.
- Local OCR is called only when the remote model fails or returns no usable quotes.
- The quote extraction prompt now explicitly handles bracketed or side-lined paragraphs:
  - extract every readable line inside the bracket or side-line span;
  - do not limit extraction to the underlined sentence when an underline appears inside a larger bracketed passage.

## Acceptance Criteria

- [x] Remote model extraction runs before on-device OCR.
- [x] Local OCR remains available as fallback if the remote model fails.
- [x] The prompt describes bracketed/side-lined paragraph extraction precisely.
- [x] Focused characterization tests cover the model-first orchestration and prompt wording.

## Verification

Command:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testModelAssistedExtractorUsesRemoteModelBeforeLocalOCR \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testModelAssistedExtractorFallsBackToLocalOCRWhenRemoteModelFails \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests/testBuildPromptTreatsBracketedParagraphsAsCompleteMarkedPassages \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests/testBuildPromptRequestsBestEffortMarkedTextWhenBoundariesAreUncertain
```

Result:

- Passed.

## Remaining Risk

This verifies orchestration and prompt construction in the simulator. The quality of the remote model on the real photographed page still needs TestFlight validation with the failing bracketed-paragraph image.
