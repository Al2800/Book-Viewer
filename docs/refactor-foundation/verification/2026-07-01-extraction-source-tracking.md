# 2026-07-01: Extraction Source Tracking

## Scope

Issue 013 requires the app to record whether a quote came from on-device extraction, model-assisted extraction, or manual entry. This slice keeps that source metadata on the existing quote-review data path rather than adding a new persistence or UI surface.

## Characterization

Added or extended focused tests for observable behavior:

- `GeminiServiceTests.testParseQuoteResponse_MissingExtractionSourceDefaultsToUnknown`
- `GeminiServiceTests.testParseQuoteResponse_ExplicitExtractionSourceIsPreserved`
- `OnDeviceQuoteExtractorTests.testExtractsUnderlinedTextFromSyntheticPageWithoutNetwork`
- `OnDeviceQuoteExtractorTests.testRemoteModelQuoteExtractorCallsModelAssistedProxyRoute`
- `ExtractionReviewQuoteStateTests.testLoadingPageSnapshotsMapsExtractedQuotesIntoEditableReviewState`
- `ExtractionReviewQuoteStateTests.testManualEditableQuoteRecordsManualExtractionSource`

The initial red run failed at compile because `ExtractedQuoteData` had no `extractionSource` member, proving the behavior was not represented in the current model.

## Implementation

- Added `QuoteExtractionSource` with `onDevice`, `modelAssisted`, `manual`, and `unknown`.
- Added `extractionSource` to `ExtractedQuoteData`.
- Added custom decoding so existing JSON without the field defaults to `unknown`.
- Stamped on-device extractor output as `onDevice`.
- Stamped remote model-assisted output as `modelAssisted`.
- Carried source metadata into editable quote-review state.
- Marked manually-created editable quotes as `manual`.

## Verification

Focused red run before implementation:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/GeminiServiceTests/testParseQuoteResponse_MissingExtractionSourceDefaultsToUnknown \
  -only-testing:BookQuotesTests/GeminiServiceTests/testParseQuoteResponse_ExplicitExtractionSourceIsPreserved \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testExtractsUnderlinedTextFromSyntheticPageWithoutNetwork \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testRemoteModelQuoteExtractorCallsModelAssistedProxyRoute
```

Result: failed as expected at compile.

- Failure: `ExtractedQuoteData` had no member `extractionSource`.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-27-25-+0100.xcresult`

Focused green run after implementation:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/GeminiServiceTests/testParseQuoteResponse_MissingExtractionSourceDefaultsToUnknown \
  -only-testing:BookQuotesTests/GeminiServiceTests/testParseQuoteResponse_ExplicitExtractionSourceIsPreserved \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testExtractsUnderlinedTextFromSyntheticPageWithoutNetwork \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testRemoteModelQuoteExtractorCallsModelAssistedProxyRoute \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests/testLoadingPageSnapshotsMapsExtractedQuotesIntoEditableReviewState \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests/testManualEditableQuoteRecordsManualExtractionSource
```

Result: passed.

- 6 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-30-44-+0100.xcresult`

Focused refactor gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/GeminiServiceTests \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/PageCaptureTests
```

Result: passed.

- 55 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-33-29-+0100.xcresult`

Static checks:

```sh
git diff --check
plutil -lint BookQuotes.xcodeproj/project.pbxproj
```

Result: passed.

## Residual Risk

- This records source metadata for review state and extraction result parsing. It does not yet expose source metadata in the UI.
- Issue 013 remains open for real-photo hosted-model quality, strict normalized model JSON guarantees, and small bracket/tick recognition.
